defmodule IbEx.OrderManagerTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.ContractResolver
  alias IbEx.OrderManager
  alias IbEx.Client.Proto.Protobuf, as: Proto

  # ---------------------------------------------------------------------------
  # Mock connection modules
  # ---------------------------------------------------------------------------

  defmodule MockConnection do
    @moduledoc false
    use GenServer

    def start_link(opts) do
      client = Keyword.fetch!(opts, :client)
      GenServer.start_link(__MODULE__, %{client: client})
    end

    def send_message(_pid, _msg), do: :ok

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call(_, _, state), do: {:reply, :ok, state}
  end

  defmodule RecordingConnection do
    @moduledoc false
    use GenServer

    def start_link(opts) do
      client = Keyword.fetch!(opts, :client)
      GenServer.start_link(__MODULE__, %{client: client})
    end

    def send_message(pid, msg) do
      GenServer.call(pid, {:send_message, msg})
    end

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call({:send_message, msg}, _from, state) do
      case :ets.lookup(:order_manager_test_pids, state.client) do
        [{_, test_pid}] -> send(test_pid, {:tws_sent, msg})
        [] -> :ok
      end

      {:reply, :ok, state}
    end
  end

  # ---------------------------------------------------------------------------
  # Wire encoding helpers
  # ---------------------------------------------------------------------------

  @open_order_wire_id 205
  @order_status_wire_id 203
  @order_bound_wire_id 300
  @contract_data_wire_id 210
  @contract_data_end_wire_id 252

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp inject_next_valid_id(client, next_valid_id) do
    proto_payload = %Proto.NextValidId{order_id: next_valid_id} |> Protobuf.encode()
    wire_msg = <<209::big-integer-size(32), proto_payload::binary>>
    Client.process_message(client, wire_msg)
    Process.sleep(20)
  end

  defp start_recording_client(next_valid_id) do
    {:ok, client} = Client.start_link(connection_handler: RecordingConnection)
    :ets.insert(:order_manager_test_pids, {client, self()})
    inject_next_valid_id(client, next_valid_id)
    client
  end

  defp start_resolver(client) do
    {:ok, resolver} = ContractResolver.start_link(client: client)
    resolver
  end

  defp start_pubsub do
    name = :"pubsub_#{System.unique_integer([:positive])}"
    {:ok, _} = Phoenix.PubSub.Supervisor.start_link(name: name)
    name
  end

  defp start_manager(client, resolver, pubsub) do
    {:ok, manager} = OrderManager.start_link(client: client, resolver: resolver, pubsub: pubsub)
    manager
  end

  defp inject_contract_data(client, req_id, contracts) do
    for contract_data <- contracts do
      Client.process_message(client, wire_message(@contract_data_wire_id, %{contract_data | req_id: req_id}))
    end

    end_marker = %Proto.ContractDataEnd{req_id: req_id}
    Client.process_message(client, wire_message(@contract_data_end_wire_id, end_marker))
  end

  defp extract_req_id_from_tws_message do
    receive do
      {:tws_sent, sent_msg} ->
        <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
        decoded = Protobuf.decode(payload, Proto.ContractDataRequest)
        decoded.req_id
    after
      1_000 -> raise "No TWS message received"
    end
  end

  defp aapl_contract_data(req_id) do
    %Proto.ContractData{
      req_id: req_id,
      contract: %Proto.Contract{
        con_id: 265_598,
        symbol: "AAPL",
        sec_type: "STK",
        currency: "USD",
        exchange: "SMART"
      },
      contract_details: %Proto.ContractDetails{long_name: "APPLE INC", market_name: "NMS"}
    }
  end

  # Places a shorthand order, handling the async resolver dance plus the perm_id confirmation.
  # Returns :ok on success.
  defp place_and_confirm(manager, client, order_id, contract_spec, action, quantity, opts \\ []) do
    perm_id = Keyword.get(opts, :_perm_id, 99999)
    session_order_id = Keyword.get(opts, :_session_order_id, 100)
    place_opts = Keyword.drop(opts, [:_perm_id, :_session_order_id])

    task =
      Task.async(fn ->
        OrderManager.place(manager, order_id, contract_spec, action, quantity, place_opts)
      end)

    Process.sleep(50)

    # Handle the resolver contract data request
    req_id = extract_req_id_from_tws_message()
    inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

    # Consume the PlaceOrder TWS message
    assert_receive {:tws_sent, _place_msg}, 1_000

    # Inject an OrderBound with perm_id to unblock the place call
    order_bound = %Proto.OrderBound{order_id: session_order_id, client_id: 0, perm_id: perm_id}
    Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))

    Task.await(task, 5_000)
  end

  # Places a shorthand order but does NOT inject the perm_id confirmation.
  # Returns the Task so the caller can control the confirmation timing.
  defp place_without_confirm(manager, client, order_id, contract_spec, action, quantity, opts \\ []) do
    task =
      Task.async(fn ->
        OrderManager.place(manager, order_id, contract_spec, action, quantity, opts)
      end)

    Process.sleep(50)

    req_id = extract_req_id_from_tws_message()
    inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

    # Consume the PlaceOrder TWS message
    assert_receive {:tws_sent, _place_msg}, 1_000

    task
  end

  # ---------------------------------------------------------------------------
  # Setup
  # ---------------------------------------------------------------------------

  setup_all do
    :ets.new(:order_manager_test_pids, [:named_table, :public, :set])
    :ok
  end

  setup do
    pubsub = start_pubsub()
    client = start_recording_client(100)
    resolver = start_resolver(client)
    manager = start_manager(client, resolver, pubsub)

    %{pubsub: pubsub, client: client, resolver: resolver, manager: manager}
  end

  # ---------------------------------------------------------------------------
  # start_link/1
  # ---------------------------------------------------------------------------

  describe "start_link/1" do
    test "starts the Order Manager with required options", %{client: client, resolver: resolver, pubsub: pubsub} do
      {:ok, manager} = OrderManager.start_link(client: client, resolver: resolver, pubsub: pubsub)
      assert Process.alive?(manager)
    end

    test "accepts an optional name", %{client: client, resolver: resolver, pubsub: pubsub} do
      name = :"test_order_manager_#{System.unique_integer([:positive])}"
      {:ok, _manager} = OrderManager.start_link(client: client, resolver: resolver, pubsub: pubsub, name: name)
      assert Process.whereis(name) != nil
    end
  end

  # ---------------------------------------------------------------------------
  # place/6 — order type inference
  # ---------------------------------------------------------------------------

  describe "place/6 order type inference" do
    test "places a market order when no price keywords are given", %{manager: manager, client: client} do
      assert :ok = place_and_confirm(manager, client, "mkt-1", {:stock, "AAPL"}, :buy, 100)
    end

    test "sends correct MKT order fields to TWS", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "mkt-wire", {:stock, "AAPL"}, :buy, 100, [])
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)

      assert decoded.order.action == "BUY"
      assert decoded.order.total_quantity == "100"
      assert decoded.order.order_type == "MKT"
      assert decoded.order.tif == "DAY"
      assert decoded.order.transmit == true
      assert decoded.order.outside_rth == false
      assert is_nil(decoded.order.lmt_price)
      assert is_nil(decoded.order.aux_price)

      # Confirm to unblock
      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 11111}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "places a limit order when limit: price is given", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "lmt-1", {:stock, "AAPL"}, :buy, 50, limit: 150.0)
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)

      assert decoded.order.order_type == "LMT"
      assert decoded.order.lmt_price == 150.0
      assert is_nil(decoded.order.aux_price)
      assert decoded.order.total_quantity == "50"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 22222}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "places a stop order when stop: price is given", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "stp-1", {:stock, "AAPL"}, :sell, 25, stop: 140.0)
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)

      assert decoded.order.order_type == "STP"
      assert decoded.order.aux_price == 140.0
      assert is_nil(decoded.order.lmt_price)
      assert decoded.order.action == "SELL"
      assert decoded.order.total_quantity == "25"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 33333}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "places a stop-limit order when both stop: and limit: are given", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "stplmt-1", {:stock, "AAPL"}, :sell, 75, stop: 140.0, limit: 135.0)
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)

      assert decoded.order.order_type == "STP LMT"
      assert decoded.order.aux_price == 140.0
      assert decoded.order.lmt_price == 135.0

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 44444}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "handles integer limit prices by converting to float", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "int-lmt-1", {:stock, "AAPL"}, :buy, 10, limit: 150)
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)

      assert decoded.order.lmt_price == 150.0
      assert decoded.order.order_type == "LMT"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 55555}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end
  end

  # ---------------------------------------------------------------------------
  # place/6 — action mapping
  # ---------------------------------------------------------------------------

  describe "place/6 action mapping" do
    test "maps :buy to BUY string", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "buy-1", {:stock, "AAPL"}, :buy, 10, [])
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.action == "BUY"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 66666}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "maps :sell to SELL string", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "sell-1", {:stock, "AAPL"}, :sell, 10, [])
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.action == "SELL"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 77777}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end
  end

  # ---------------------------------------------------------------------------
  # place/6 — default values and options
  # ---------------------------------------------------------------------------

  describe "place/6 default values" do
    test "uses DAY as default tif", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "tif-1", {:stock, "AAPL"}, :buy, 10, [])
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.tif == "DAY"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 88888}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "accepts custom tif as atom", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "tif-gtc", {:stock, "AAPL"}, :buy, 10, tif: :gtc, limit: 150.0)
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.tif == "GTC"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 99999}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "defaults transmit to true", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "tx-default", {:stock, "AAPL"}, :buy, 10, [])
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.transmit == true

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 11111}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "accepts transmit: false option", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "tx-false", {:stock, "AAPL"}, :buy, 10, transmit: false)
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.transmit == false

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 22222}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "defaults outside_rth to false", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "rth-default", {:stock, "AAPL"}, :buy, 10, [])
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.outside_rth == false

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 33333}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "accepts outside_rth: true option", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "rth-true", {:stock, "AAPL"}, :buy, 10, outside_rth: true)
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.order.outside_rth == true

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 44444}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "resolves contract from ContractResolver and uses its fields", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "resolve-1", {:stock, "AAPL"}, :buy, 10, [])
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.contract.symbol == "AAPL"
      assert decoded.contract.sec_type == "STK"
      assert decoded.contract.currency == "USD"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 55555}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "allows overriding exchange via opts", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "exch-1", {:stock, "AAPL"}, :buy, 10, exchange: "NASDAQ")
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.contract.exchange == "NASDAQ"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 66666}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end

    test "allows overriding currency via opts", %{pubsub: pubsub} do
      client = start_recording_client(200)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          OrderManager.place(manager, "curr-1", {:stock, "AAPL"}, :buy, 10, currency: "EUR")
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, place_msg}, 1_000
      <<_wire_id::big-integer-size(32), place_payload::binary>> = place_msg
      decoded = Protobuf.decode(place_payload, Proto.PlaceOrderRequest)
      assert decoded.contract.currency == "EUR"

      order_bound = %Proto.OrderBound{order_id: 200, client_id: 0, perm_id: 77777}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))
      assert :ok = Task.await(task, 5_000)
    end
  end

  # ---------------------------------------------------------------------------
  # place/6 — blocking behavior
  # ---------------------------------------------------------------------------

  describe "place/6 blocking" do
    test "blocks until perm_id arrives via OrderBound", %{manager: manager, client: client} do
      task = place_without_confirm(manager, client, "block-1", {:stock, "AAPL"}, :buy, 100)

      # Task should not have completed yet
      refute Task.yield(task, 100)

      # Now inject the OrderBound with perm_id > 0
      order_bound = %Proto.OrderBound{order_id: 100, client_id: 0, perm_id: 12345}
      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))

      assert :ok = Task.await(task, 5_000)
    end

    test "blocks until perm_id arrives via OrderStatus", %{manager: manager, client: client} do
      task = place_without_confirm(manager, client, "block-2", {:stock, "AAPL"}, :buy, 100)

      # Task should not have completed yet
      refute Task.yield(task, 100)

      # Inject OrderStatus with perm_id > 0
      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "PreSubmitted",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 12345
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert :ok = Task.await(task, 5_000)
    end

    test "does not unblock on OrderStatus with perm_id 0", %{manager: manager, client: client} do
      task = place_without_confirm(manager, client, "block-3", {:stock, "AAPL"}, :buy, 100)

      # Inject OrderStatus with perm_id == 0
      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "PreSubmitted",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 0
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      # Task should still be blocked
      refute Task.yield(task, 200)

      # Now send one with a real perm_id
      order_status_real = %Proto.OrderStatus{
        order_id: 100,
        status: "PreSubmitted",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 12345
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status_real))

      assert :ok = Task.await(task, 5_000)
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub — order_status broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub order_status broadcast" do
    test "broadcasts {:order_status, ...} with atom status on OrderStatus", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      order_id = "status-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      # Inject an OrderStatus
      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "Submitted",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 99999
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert_receive {:order_status, %{status: :submitted} = event}, 1_000
      assert Decimal.equal?(event.filled, Decimal.new("0"))
      assert Decimal.equal?(event.remaining, Decimal.new("100"))
      assert Decimal.equal?(event.avg_price, Decimal.new("0.0"))
    end

    test "maps PreSubmitted status to :pre_submitted atom", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      order_id = "ps-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "PreSubmitted",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 99999
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert_receive {:order_status, %{status: :pre_submitted}}, 1_000
    end

    test "maps Filled status to :filled atom with parsed numbers", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      order_id = "filled-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "Filled",
        filled: "100",
        remaining: "0",
        avg_fill_price: 150.25,
        perm_id: 99999
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert_receive {:order_status, %{status: :filled} = event}, 1_000
      assert Decimal.equal?(event.filled, Decimal.new("100"))
      assert Decimal.equal?(event.remaining, Decimal.new("0"))
      assert Decimal.equal?(event.avg_price, Decimal.from_float(150.25))
    end

    test "maps Cancelled status to :cancelled atom", %{manager: manager, client: client, pubsub: pubsub} do
      order_id = "cancel-status-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "Cancelled",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 99999
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert_receive {:order_status, %{status: :cancelled}}, 1_000
    end

    test "maps Inactive status to :inactive atom", %{manager: manager, client: client, pubsub: pubsub} do
      order_id = "inactive-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "Inactive",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 99999
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert_receive {:order_status, %{status: :inactive}}, 1_000
    end

    test "maps ApiCancelled status to :api_cancelled atom", %{manager: manager, client: client, pubsub: pubsub} do
      order_id = "api-cancel-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "ApiCancelled",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 99999
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert_receive {:order_status, %{status: :api_cancelled}}, 1_000
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub — order_accepted broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub order_accepted broadcast" do
    test "broadcasts {:order_accepted, %{}} on first OpenOrder", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      order_id = "accepted-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      open_order = %Proto.OpenOrder{
        order_id: 100,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "BUY", total_quantity: "100", order_type: "MKT"},
        order_state: %Proto.OrderState{status: "PreSubmitted"}
      }

      Client.process_message(client, wire_message(@open_order_wire_id, open_order))

      assert_receive {:order_accepted, %{}}, 1_000
    end

    test "does not broadcast {:order_accepted, %{}} on subsequent OpenOrders", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      order_id = "accepted-once"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      open_order = %Proto.OpenOrder{
        order_id: 100,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "BUY", total_quantity: "100", order_type: "MKT"},
        order_state: %Proto.OrderState{status: "PreSubmitted"}
      }

      Client.process_message(client, wire_message(@open_order_wire_id, open_order))
      assert_receive {:order_accepted, %{}}, 1_000

      # Send another OpenOrder (TWS sends multiple)
      Client.process_message(client, wire_message(@open_order_wire_id, open_order))
      Process.sleep(100)

      refute_receive {:order_accepted, _}
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub — order_error broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub order_error broadcast" do
    test "broadcasts {:order_error, %{code: ..., message: ...}} on Error", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      order_id = "error-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      %{refs: refs} = :sys.get_state(manager)
      [{ref, ^order_id}] = Map.to_list(refs)

      error = %IbEx.Client.Types.Error{id: 100, code: 201, message: "Order rejected"}
      send(manager, {:ib_ex, ref, {:error, error}})

      assert_receive {:order_error, %{code: 201, message: "Order rejected"}}, 1_000
    end
  end

  # ---------------------------------------------------------------------------
  # cancel/3
  # ---------------------------------------------------------------------------

  describe "cancel/3" do
    test "returns {:error, :not_found} for unknown order_id", %{manager: manager} do
      assert {:error, :not_found} = OrderManager.cancel(manager, "nonexistent")
    end

    test "delegates cancellation to Client.Orders.cancel and returns :ok", %{
      manager: manager,
      client: client
    } do
      assert :ok =
               place_and_confirm(manager, client, "cancel-me", {:stock, "AAPL"}, :buy, 100,
                 _perm_id: 12345,
                 _session_order_id: 100
               )

      assert :ok = OrderManager.cancel(manager, "cancel-me")
    end
  end

  # ---------------------------------------------------------------------------
  # Terminal status cleanup
  # ---------------------------------------------------------------------------

  describe "terminal status cleanup" do
    for status <- ~w(Filled Cancelled ApiCancelled Inactive) do
      test "cleans up internal mapping on #{status} status", %{
        manager: manager,
        client: client,
        pubsub: pubsub
      } do
        order_id = "terminal-#{unquote(status)}"
        Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

        assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

        # Verify order is tracked
        %{orders: orders_before} = :sys.get_state(manager)
        assert Map.has_key?(orders_before, order_id)

        # Send terminal status
        terminal_status = %Proto.OrderStatus{
          order_id: 100,
          status: unquote(status),
          filled: "100",
          remaining: "0",
          avg_fill_price: 150.0,
          perm_id: 99999
        }

        Client.process_message(client, wire_message(@order_status_wire_id, terminal_status))
        Process.sleep(100)

        # Internal mapping should be cleaned up
        %{orders: orders_after, refs: refs_after} = :sys.get_state(manager)
        assert not Map.has_key?(orders_after, order_id)
        assert map_size(refs_after) == 0
      end
    end

    test "cancel returns {:error, :not_found} after terminal status cleanup", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      order_id = "terminal-then-cancel"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:orders:#{order_id}")

      assert :ok = place_and_confirm(manager, client, order_id, {:stock, "AAPL"}, :buy, 100)

      filled_status = %Proto.OrderStatus{
        order_id: 100,
        status: "Filled",
        filled: "100",
        remaining: "0",
        avg_fill_price: 150.0,
        perm_id: 99999
      }

      Client.process_message(client, wire_message(@order_status_wire_id, filled_status))
      Process.sleep(100)

      assert {:error, :not_found} = OrderManager.cancel(manager, order_id)
    end
  end

  # ---------------------------------------------------------------------------
  # Unrecognized messages
  # ---------------------------------------------------------------------------

  describe "unrecognized messages" do
    test "ignores other {:ib_ex, ref, msg} message types without crashing", %{
      manager: manager,
      client: client
    } do
      assert :ok = place_and_confirm(manager, client, "ignore-1", {:stock, "AAPL"}, :buy, 100)

      %{refs: refs} = :sys.get_state(manager)
      [{ref, _}] = Map.to_list(refs)

      # Send a DeltaNeutralContract message (not explicitly handled)
      send(manager, {:ib_ex, ref, %{__struct__: SomeUnknownMessage, data: "test"}})
      Process.sleep(50)

      assert Process.alive?(manager)
    end
  end
end
