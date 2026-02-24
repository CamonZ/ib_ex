defmodule IbEx.MarketDataManagerTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.ContractResolver
  alias IbEx.MarketDataManager
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
      case :ets.lookup(:market_data_manager_test_pids, state.client) do
        [{_, test_pid}] -> send(test_pid, {:tws_sent, msg})
        [] -> :ok
      end

      {:reply, :ok, state}
    end
  end

  # ---------------------------------------------------------------------------
  # Wire encoding helpers
  # ---------------------------------------------------------------------------

  @contract_data_wire_id 210
  @contract_data_end_wire_id 252

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_recording_client do
    {:ok, client} = Client.start_link(connection_handler: RecordingConnection)
    :ets.insert(:market_data_manager_test_pids, {client, self()})
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
    {:ok, manager} = MarketDataManager.start_link(client: client, resolver: resolver, pubsub: pubsub)
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

  # Subscribes via the manager, handling the async resolver dance.
  # Returns :ok on success.
  defp subscribe_with_resolve(manager, client, subscription_id, type, contract_spec, opts \\ []) do
    task =
      Task.async(fn ->
        MarketDataManager.subscribe(manager, subscription_id, type, contract_spec, opts)
      end)

    Process.sleep(50)

    # Handle the resolver contract data request
    req_id = extract_req_id_from_tws_message()
    inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

    # Consume the subscribe request TWS message
    assert_receive {:tws_sent, _subscribe_msg}, 1_000

    Task.await(task, 5_000)
  end

  # ---------------------------------------------------------------------------
  # Setup
  # ---------------------------------------------------------------------------

  setup_all do
    :ets.new(:market_data_manager_test_pids, [:named_table, :public, :set])
    :ok
  end

  setup do
    pubsub = start_pubsub()
    client = start_recording_client()
    resolver = start_resolver(client)
    manager = start_manager(client, resolver, pubsub)

    %{pubsub: pubsub, client: client, resolver: resolver, manager: manager}
  end

  # ---------------------------------------------------------------------------
  # start_link/1
  # ---------------------------------------------------------------------------

  describe "start_link/1" do
    test "starts the Market Data Manager with required options", %{client: client, resolver: resolver, pubsub: pubsub} do
      {:ok, manager} = MarketDataManager.start_link(client: client, resolver: resolver, pubsub: pubsub)
      assert Process.alive?(manager)
    end

    test "accepts an optional name", %{client: client, resolver: resolver, pubsub: pubsub} do
      name = :"test_market_data_manager_#{System.unique_integer([:positive])}"
      {:ok, _manager} = MarketDataManager.start_link(client: client, resolver: resolver, pubsub: pubsub, name: name)
      assert Process.whereis(name) != nil
    end

    test "fails to start when :client option is missing", %{resolver: resolver, pubsub: pubsub} do
      Process.flag(:trap_exit, true)
      assert {:error, {%KeyError{key: :client}, _}} = MarketDataManager.start_link(resolver: resolver, pubsub: pubsub)
    end

    test "fails to start when :resolver option is missing", %{client: client, pubsub: pubsub} do
      Process.flag(:trap_exit, true)
      assert {:error, {%KeyError{key: :resolver}, _}} = MarketDataManager.start_link(client: client, pubsub: pubsub)
    end

    test "fails to start when :pubsub option is missing", %{client: client, resolver: resolver} do
      Process.flag(:trap_exit, true)

      assert {:error, {%KeyError{key: :pubsub}, _}} =
               MarketDataManager.start_link(client: client, resolver: resolver)
    end
  end

  # ---------------------------------------------------------------------------
  # subscribe/5
  # ---------------------------------------------------------------------------

  describe "subscribe/5" do
    test "returns :ok for :quotes type", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "aapl-quotes", :quotes, {:stock, "AAPL"})
    end

    test "returns :ok for :trades type", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "aapl-trades", :trades, {:stock, "AAPL"})
    end

    test "returns :ok for :depth type", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "aapl-depth", :depth, {:stock, "AAPL"})
    end

    test "tracks subscription with correct type in internal state", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "tracked-quotes", :quotes, {:stock, "AAPL"})

      %{subscriptions: subscriptions, refs: refs} = :sys.get_state(manager)
      assert %{client_ref: _ref, type: :quotes} = subscriptions["tracked-quotes"]
      assert map_size(refs) == 1
    end

    test "tracks :trades type in internal state", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "tracked-trades", :trades, {:stock, "AAPL"})

      %{subscriptions: subscriptions} = :sys.get_state(manager)
      assert %{type: :trades} = subscriptions["tracked-trades"]
    end

    test "tracks :depth type in internal state", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "tracked-depth", :depth, {:stock, "AAPL"})

      %{subscriptions: subscriptions} = :sys.get_state(manager)
      assert %{type: :depth} = subscriptions["tracked-depth"]
    end

    test "cancels previous subscription when reusing subscription_id", %{pubsub: pubsub} do
      client = start_recording_client()
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      assert :ok = subscribe_with_resolve(manager, client, "reused", :quotes, {:stock, "AAPL"})

      %{subscriptions: subs1} = :sys.get_state(manager)
      old_ref = subs1["reused"].client_ref

      # Second subscribe with same ID -- manually handle the cancel + resolver dance.
      # Using {:stock, "AAPL", "USD"} to avoid resolver cache hit.
      task =
        Task.async(fn ->
          MarketDataManager.subscribe(manager, "reused", :trades, {:stock, "AAPL", "USD"})
        end)

      Process.sleep(50)

      # Drain the cancel message sent for the old subscription
      assert_receive {:tws_sent, _cancel_msg}, 1_000

      # Handle the resolver contract data request
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      # Consume the new subscribe request
      assert_receive {:tws_sent, _subscribe_msg}, 1_000

      assert :ok = Task.await(task, 5_000)

      %{subscriptions: subs2, refs: refs2} = :sys.get_state(manager)
      new_ref = subs2["reused"].client_ref

      assert new_ref != old_ref
      refute Map.has_key?(refs2, old_ref)
      assert refs2[new_ref] == "reused"
      assert map_size(refs2) == 1
      assert subs2["reused"].type == :trades
    end

    test "sends MarketDataRequest to TWS for :quotes type", %{pubsub: pubsub} do
      client = start_recording_client()
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          MarketDataManager.subscribe(manager, "wire-quotes", :quotes, {:stock, "AAPL"})
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, subscribe_msg}, 1_000
      <<_wire_id::big-integer-size(32), payload::binary>> = subscribe_msg
      decoded = Protobuf.decode(payload, Proto.MarketDataRequest)

      assert %Proto.MarketDataRequest{} = decoded
      assert decoded.contract.symbol == "AAPL"
      assert decoded.contract.sec_type == "STK"
      assert decoded.snapshot == nil

      assert :ok = Task.await(task, 5_000)
    end

    test "sends TickByTickRequest to TWS for :trades type", %{pubsub: pubsub} do
      client = start_recording_client()
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          MarketDataManager.subscribe(manager, "wire-trades", :trades, {:stock, "AAPL"})
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, subscribe_msg}, 1_000
      <<_wire_id::big-integer-size(32), payload::binary>> = subscribe_msg
      decoded = Protobuf.decode(payload, Proto.TickByTickRequest)

      assert %Proto.TickByTickRequest{} = decoded
      assert decoded.contract.symbol == "AAPL"
      assert decoded.contract.sec_type == "STK"
      assert decoded.tick_type == "Last"

      assert :ok = Task.await(task, 5_000)
    end

    test "sends MarketDepthRequest to TWS for :depth type", %{pubsub: pubsub} do
      client = start_recording_client()
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          MarketDataManager.subscribe(manager, "wire-depth", :depth, {:stock, "AAPL"})
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, subscribe_msg}, 1_000
      <<_wire_id::big-integer-size(32), payload::binary>> = subscribe_msg
      decoded = Protobuf.decode(payload, Proto.MarketDepthRequest)

      assert %Proto.MarketDepthRequest{} = decoded
      assert decoded.contract.symbol == "AAPL"
      assert decoded.contract.sec_type == "STK"
      assert decoded.num_rows == 5

      assert :ok = Task.await(task, 5_000)
    end

    test "returns {:error, :invalid_args} for non-string subscription_id", %{manager: manager} do
      assert {:error, :invalid_args} = MarketDataManager.subscribe(manager, 123, :quotes, {:stock, "AAPL"})
      assert {:error, :invalid_args} = MarketDataManager.subscribe(manager, :atom_id, :quotes, {:stock, "AAPL"})
    end

    test "returns {:error, :invalid_args} for invalid type", %{manager: manager} do
      assert {:error, :invalid_args} = MarketDataManager.subscribe(manager, "sub-1", :invalid, {:stock, "AAPL"})
      assert {:error, :invalid_args} = MarketDataManager.subscribe(manager, "sub-1", "quotes", {:stock, "AAPL"})
    end

    test "returns {:error, :invalid_args} for non-tuple contract_spec", %{manager: manager} do
      assert {:error, :invalid_args} = MarketDataManager.subscribe(manager, "sub-1", :quotes, "AAPL")
      assert {:error, :invalid_args} = MarketDataManager.subscribe(manager, "sub-1", :quotes, 42)
    end
  end

  # ---------------------------------------------------------------------------
  # unsubscribe/2
  # ---------------------------------------------------------------------------

  describe "unsubscribe/2" do
    test "returns :ok for an active subscription", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "unsub-ok", :quotes, {:stock, "AAPL"})
      assert :ok = MarketDataManager.unsubscribe(manager, "unsub-ok")
    end

    test "returns {:error, :not_found} for unknown subscription_id", %{manager: manager} do
      assert {:error, :not_found} = MarketDataManager.unsubscribe(manager, "nonexistent")
    end

    test "cleans up internal state after unsubscription", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "cleanup-sub", :quotes, {:stock, "AAPL"})

      %{subscriptions: subs_before, refs: refs_before} = :sys.get_state(manager)
      assert Map.has_key?(subs_before, "cleanup-sub")
      assert map_size(refs_before) == 1

      assert :ok = MarketDataManager.unsubscribe(manager, "cleanup-sub")

      %{subscriptions: subs_after, refs: refs_after} = :sys.get_state(manager)
      refute Map.has_key?(subs_after, "cleanup-sub")
      assert subs_after == %{}
      assert refs_after == %{}
    end

    test "returns {:error, :invalid_args} for non-string subscription_id", %{manager: manager} do
      assert {:error, :invalid_args} = MarketDataManager.unsubscribe(manager, 123)
      assert {:error, :invalid_args} = MarketDataManager.unsubscribe(manager, :atom_id)
    end
  end

  # ---------------------------------------------------------------------------
  # subscriptions/1
  # ---------------------------------------------------------------------------

  describe "subscriptions/1" do
    test "returns empty list when no subscriptions", %{manager: manager} do
      assert MarketDataManager.subscriptions(manager) == []
    end

    test "returns list of active subscription IDs", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "sub-a", :quotes, {:stock, "AAPL"})
      assert :ok = subscribe_with_resolve(manager, client, "sub-b", :trades, {:stock, "AAPL", "USD"})

      subs = MarketDataManager.subscriptions(manager)
      assert length(subs) == 2
      assert "sub-a" in subs
      assert "sub-b" in subs
    end

    test "does not include unsubscribed IDs", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "sub-keep", :quotes, {:stock, "AAPL"})
      assert :ok = subscribe_with_resolve(manager, client, "sub-remove", :trades, {:stock, "AAPL", "USD"})

      assert :ok = MarketDataManager.unsubscribe(manager, "sub-remove")

      subs = MarketDataManager.subscriptions(manager)
      assert subs == ["sub-keep"]
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- market_data_error broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub market_data_error broadcast" do
    test "broadcasts {:market_data_error, %{code: ..., message: ...}} on Error", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "error-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      error = %IbEx.Client.Types.Error{id: 1, code: 354, message: "Requested market data is not subscribed"}
      send(manager, {:ib_ex, client_ref, {:error, error}})

      assert_receive {:market_data_error, event}, 1_000
      assert event.code == 354
      assert event.message == "Requested market data is not subscribed"
    end

    test "ignores errors for unknown refs", %{manager: manager, pubsub: pubsub} do
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:phantom")

      unknown_ref = make_ref()
      error = %IbEx.Client.Types.Error{id: 1, code: 354, message: "Not subscribed"}
      send(manager, {:ib_ex, unknown_ref, {:error, error}})

      refute_receive {:market_data_error, _}, 200
    end

    test "does not broadcast error after unsubscription", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "error-unsub"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      assert :ok = MarketDataManager.unsubscribe(manager, sub_id)

      error = %IbEx.Client.Types.Error{id: 1, code: 354, message: "Not subscribed"}
      send(manager, {:ib_ex, client_ref, {:error, error}})

      refute_receive {:market_data_error, _}, 200
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- TickPrice broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub TickPrice broadcast" do
    test "broadcasts {:tick_price, ...} with resolved tick_type atom and Decimal values", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-price-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickPrice{req_id: 1, tick_type: 1, price: 150.25, size: "100", attr_mask: 3}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_price, event}, 1_000
      assert event.tick_type == :bid
      assert Decimal.equal?(event.price, Decimal.from_float(150.25))
      assert Decimal.equal?(event.size, Decimal.new("100"))
      assert event.attr_mask == 3
    end

    test "resolves tick_type 2 to :ask", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "tick-price-ask"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickPrice{req_id: 1, tick_type: 2, price: 151.50, size: "200", attr_mask: 0}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_price, event}, 1_000
      assert event.tick_type == :ask
      assert Decimal.equal?(event.price, Decimal.from_float(151.50))
      assert Decimal.equal?(event.size, Decimal.new("200"))
      assert event.attr_mask == 0
    end

    test "falls back to raw integer for unknown tick_type", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-price-unknown"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickPrice{req_id: 1, tick_type: 99999, price: 100.0, size: "50", attr_mask: 0}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_price, event}, 1_000
      assert event.tick_type == 99999
    end

    test "does not broadcast after unsubscription", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "tick-price-unsub"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      assert :ok = MarketDataManager.unsubscribe(manager, sub_id)

      msg = %Proto.TickPrice{req_id: 1, tick_type: 1, price: 150.0, size: "100", attr_mask: 0}
      send(manager, {:ib_ex, client_ref, msg})

      refute_receive {:tick_price, _}, 200
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- TickSize broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub TickSize broadcast" do
    test "broadcasts {:tick_size, ...} with resolved tick_type and Decimal size", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-size-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickSize{req_id: 1, tick_type: 0, size: "500"}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_size, event}, 1_000
      assert event.tick_type == :bid_size
      assert Decimal.equal?(event.size, Decimal.new("500"))
    end

    test "resolves tick_type 3 to :ask_size", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "tick-size-ask"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickSize{req_id: 1, tick_type: 3, size: "250"}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_size, event}, 1_000
      assert event.tick_type == :ask_size
      assert Decimal.equal?(event.size, Decimal.new("250"))
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- TickString broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub TickString broadcast" do
    test "broadcasts {:tick_string, ...} with resolved tick_type and string value", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-string-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      # tick_type 45 = :last_timestamp
      msg = %Proto.TickString{req_id: 1, tick_type: 45, value: "1708700000"}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_string, event}, 1_000
      assert event.tick_type == :last_timestamp
      assert event.value == "1708700000"
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- TickGeneric broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub TickGeneric broadcast" do
    test "broadcasts {:tick_generic, ...} with resolved tick_type and float value", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-generic-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      # tick_type 46 = :shortable
      msg = %Proto.TickGeneric{req_id: 1, tick_type: 46, value: 2.5}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_generic, event}, 1_000
      assert event.tick_type == :shortable
      assert event.value == 2.5
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- TickOptionComputation broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub TickOptionComputation broadcast" do
    test "broadcasts {:tick_option_computation, ...} with Decimal greeks", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-opt-comp-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      # tick_type 10 = :bid_option_computation
      msg = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 10,
        tick_attrib: 1,
        implied_vol: 0.35,
        delta: 0.65,
        opt_price: 12.50,
        pv_dividend: 0.25,
        gamma: 0.03,
        vega: 0.15,
        theta: -0.05,
        und_price: 150.0
      }

      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_option_computation, event}, 1_000
      assert event.tick_type == :bid_option_computation
      assert event.tick_attrib == 1
      assert Decimal.equal?(event.implied_vol, Decimal.from_float(0.35))
      assert Decimal.equal?(event.delta, Decimal.from_float(0.65))
      assert Decimal.equal?(event.opt_price, Decimal.from_float(12.50))
      assert Decimal.equal?(event.pv_dividend, Decimal.from_float(0.25))
      assert Decimal.equal?(event.gamma, Decimal.from_float(0.03))
      assert Decimal.equal?(event.vega, Decimal.from_float(0.15))
      assert Decimal.equal?(event.theta, Decimal.from_float(-0.05))
      assert Decimal.equal?(event.und_price, Decimal.from_float(150.0))
    end

    test "handles nil greeks values", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "tick-opt-comp-nil"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 10,
        tick_attrib: 0,
        implied_vol: nil,
        delta: nil,
        opt_price: nil,
        pv_dividend: nil,
        gamma: nil,
        vega: nil,
        theta: nil,
        und_price: nil
      }

      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_option_computation, event}, 1_000
      assert event.tick_type == :bid_option_computation
      assert event.implied_vol == nil
      assert event.delta == nil
      assert event.opt_price == nil
      assert event.pv_dividend == nil
      assert event.gamma == nil
      assert event.vega == nil
      assert event.theta == nil
      assert event.und_price == nil
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- TickReqParams broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub TickReqParams broadcast" do
    test "broadcasts {:tick_req_params, ...} with correct fields", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-req-params-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickReqParams{req_id: 1, min_tick: "0.01", bbo_exchange: "SMART", snapshot_permissions: 3}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_req_params, event}, 1_000
      assert event.min_tick == "0.01"
      assert event.bbo_exchange == "SMART"
      assert event.snapshot_permissions == 3
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- TickSnapshotEnd broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub TickSnapshotEnd broadcast" do
    test "broadcasts {:tick_snapshot_end, %{}} on snapshot end", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tick-snapshot-end-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :quotes, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      msg = %Proto.TickSnapshotEnd{req_id: 1}
      send(manager, {:ib_ex, client_ref, msg})

      assert_receive {:tick_snapshot_end, event}, 1_000
      assert event == %{}
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- trades broadcast (tick-by-tick)
  # ---------------------------------------------------------------------------

  describe "PubSub trades broadcast" do
    test "broadcasts {:trade, ...} on TickByTickData with historical_tick_last", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tbt-trade-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :trades, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      tick_msg = %Proto.TickByTickData{
        req_id: 1,
        tick_type: 1,
        tick:
          {:historical_tick_last,
           %Proto.HistoricalTickLast{
             time: 1_700_000_000,
             price: 185.50,
             size: "100",
             exchange: "ARCA",
             special_conditions: "T",
             tick_attrib_last: %Proto.TickAttribLast{
               past_limit: true,
               unreported: false
             }
           }}
      }

      send(manager, {:ib_ex, client_ref, tick_msg})

      assert_receive {:trade, event}, 1_000

      assert event.timestamp == ~U[2023-11-14 22:13:20Z]
      assert Decimal.equal?(event.price, Decimal.from_float(185.50))
      assert Decimal.equal?(event.size, Decimal.new("100"))
      assert event.exchange == "ARCA"
      assert event.special_conditions == "T"
      assert event.past_limit == true
      assert event.unreported == false
    end

    test "broadcasts {:bid_ask, ...} on TickByTickData with historical_tick_bid_ask", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tbt-bidask-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :trades, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      tick_msg = %Proto.TickByTickData{
        req_id: 2,
        tick_type: 3,
        tick:
          {:historical_tick_bid_ask,
           %Proto.HistoricalTickBidAsk{
             time: 1_700_000_100,
             price_bid: 185.45,
             price_ask: 185.55,
             size_bid: "200",
             size_ask: "150",
             tick_attrib_bid_ask: %Proto.TickAttribBidAsk{
               bid_past_low: true,
               ask_past_high: false
             }
           }}
      }

      send(manager, {:ib_ex, client_ref, tick_msg})

      assert_receive {:bid_ask, event}, 1_000

      assert event.timestamp == ~U[2023-11-14 22:15:00Z]
      assert Decimal.equal?(event.bid_price, Decimal.from_float(185.45))
      assert Decimal.equal?(event.ask_price, Decimal.from_float(185.55))
      assert Decimal.equal?(event.bid_size, Decimal.new("200"))
      assert Decimal.equal?(event.ask_size, Decimal.new("150"))
      assert event.bid_past_low == true
      assert event.ask_past_high == false
    end

    test "broadcasts {:mid_point, ...} on TickByTickData with historical_tick_mid_point", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tbt-midpoint-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :trades, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      tick_msg = %Proto.TickByTickData{
        req_id: 3,
        tick_type: 4,
        tick:
          {:historical_tick_mid_point,
           %Proto.HistoricalTick{
             time: 1_700_000_200,
             price: 185.50
           }}
      }

      send(manager, {:ib_ex, client_ref, tick_msg})

      assert_receive {:mid_point, event}, 1_000

      assert event.timestamp == ~U[2023-11-14 22:16:40Z]
      assert Decimal.equal?(event.price, Decimal.from_float(185.50))
    end

    test "handles nil tick_attrib_last gracefully (defaults booleans to false)", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tbt-nil-attrib-last"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :trades, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      tick_msg = %Proto.TickByTickData{
        req_id: 4,
        tick_type: 1,
        tick:
          {:historical_tick_last,
           %Proto.HistoricalTickLast{
             time: 1_700_000_300,
             price: 186.00,
             size: "50",
             exchange: "NYSE",
             special_conditions: "",
             tick_attrib_last: nil
           }}
      }

      send(manager, {:ib_ex, client_ref, tick_msg})

      assert_receive {:trade, event}, 1_000

      assert event.past_limit == false
      assert event.unreported == false
    end

    test "handles nil tick_attrib_bid_ask gracefully (defaults booleans to false)", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tbt-nil-attrib-bidask"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :trades, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      tick_msg = %Proto.TickByTickData{
        req_id: 5,
        tick_type: 3,
        tick:
          {:historical_tick_bid_ask,
           %Proto.HistoricalTickBidAsk{
             time: 1_700_000_400,
             price_bid: 186.10,
             price_ask: 186.20,
             size_bid: "300",
             size_ask: "250",
             tick_attrib_bid_ask: nil
           }}
      }

      send(manager, {:ib_ex, client_ref, tick_msg})

      assert_receive {:bid_ask, event}, 1_000

      assert event.bid_past_low == false
      assert event.ask_past_high == false
    end

    test "does not broadcast after unsubscription", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "tbt-unsub"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :trades, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      assert :ok = MarketDataManager.unsubscribe(manager, sub_id)

      tick_msg = %Proto.TickByTickData{
        req_id: 6,
        tick_type: 1,
        tick:
          {:historical_tick_last,
           %Proto.HistoricalTickLast{
             time: 1_700_000_500,
             price: 187.00,
             size: "75",
             exchange: "ARCA",
             special_conditions: "",
             tick_attrib_last: %Proto.TickAttribLast{past_limit: false, unreported: false}
           }}
      }

      send(manager, {:ib_ex, client_ref, tick_msg})

      refute_receive {:trade, _}, 200
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- depth broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub depth broadcast" do
    test "broadcasts {:depth_update, ...} on MarketDepth with correct fields", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "depth-l1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{
        position: 0,
        operation: 0,
        side: 1,
        price: 150.25,
        size: "100",
        market_maker: "",
        is_smart_depth: false
      }

      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.position == 0
      assert event.operation == :insert
      assert event.side == :bid
      assert Decimal.equal?(event.price, Decimal.from_float(150.25))
      assert Decimal.equal?(event.size, Decimal.new("100"))
      assert event.market_maker == ""
      assert event.is_smart_depth == false
    end

    test "broadcasts {:depth_update, ...} on MarketDepthL2 with market_maker populated", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "depth-l2"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{
        position: 2,
        operation: 1,
        side: 0,
        price: 149.50,
        size: "200",
        market_maker: "GSCO",
        is_smart_depth: true
      }

      send(manager, {:ib_ex, client_ref, %Proto.MarketDepthL2{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.position == 2
      assert event.operation == :update
      assert event.side == :ask
      assert Decimal.equal?(event.price, Decimal.from_float(149.50))
      assert Decimal.equal?(event.size, Decimal.new("200"))
      assert event.market_maker == "GSCO"
      assert event.is_smart_depth == true
    end

    test "correctly maps operation 0 to :insert", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-op-insert"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{position: 0, operation: 0, side: 1, price: 100.0, size: "10"}
      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.operation == :insert
    end

    test "correctly maps operation 1 to :update", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-op-update"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{position: 1, operation: 1, side: 0, price: 101.0, size: "20"}
      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.operation == :update
    end

    test "correctly maps operation 2 to :delete", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-op-delete"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{position: 3, operation: 2, side: 1, price: 99.0, size: "5"}
      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.operation == :delete
    end

    test "correctly maps side 0 to :ask", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-side-ask"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{position: 0, operation: 0, side: 0, price: 150.0, size: "50"}
      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.side == :ask
    end

    test "correctly maps side 1 to :bid", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-side-bid"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{position: 0, operation: 0, side: 1, price: 149.0, size: "75"}
      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.side == :bid
    end

    test "handles nil market_maker by defaulting to empty string", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-nil-mm"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{
        position: 0,
        operation: 0,
        side: 1,
        price: 150.0,
        size: "100",
        market_maker: nil,
        is_smart_depth: true
      }

      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.market_maker == ""
    end

    test "handles nil is_smart_depth by defaulting to false", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-nil-smart"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      depth_data = %Proto.MarketDepthData{
        position: 0,
        operation: 0,
        side: 1,
        price: 150.0,
        size: "100",
        market_maker: "ARCA",
        is_smart_depth: nil
      }

      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      assert_receive {:depth_update, event}, 1_000
      assert event.is_smart_depth == false
    end

    test "does not broadcast after unsubscription", %{manager: manager, client: client, pubsub: pubsub} do
      sub_id = "depth-unsub"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:market_data:#{sub_id}")
      assert :ok = subscribe_with_resolve(manager, client, sub_id, :depth, {:stock, "AAPL"})
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      assert :ok = MarketDataManager.unsubscribe(manager, sub_id)

      depth_data = %Proto.MarketDepthData{position: 0, operation: 0, side: 1, price: 150.0, size: "100"}
      send(manager, {:ib_ex, client_ref, %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}})

      refute_receive {:depth_update, _}, 200
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
      assert :ok = subscribe_with_resolve(manager, client, "ignore-1", :quotes, {:stock, "AAPL"})

      %{refs: refs} = :sys.get_state(manager)
      [{ref, _}] = Map.to_list(refs)

      # Send a TickPrice message (not explicitly handled in skeleton)
      send(manager, {:ib_ex, ref, %Proto.TickPrice{req_id: 1, tick_type: 1, price: 150.0}})
      Process.sleep(50)

      assert Process.alive?(manager)
    end

    test "ignores messages for unknown refs without crashing", %{manager: manager} do
      unknown_ref = make_ref()

      send(manager, {:ib_ex, unknown_ref, %Proto.TickPrice{req_id: 999, tick_type: 1, price: 100.0}})

      Process.sleep(50)
      assert Process.alive?(manager)
    end
  end
end
