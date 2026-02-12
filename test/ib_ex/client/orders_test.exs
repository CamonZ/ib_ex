defmodule IbEx.Client.OrdersTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.Orders
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract
  alias IbEx.Client.Types.Order, as: DomainOrder

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

    @agent_name __MODULE__.TestPidAgent

    def set_test_pid(pid) do
      case Agent.start_link(fn -> pid end, name: @agent_name) do
        {:ok, _} ->
          :ok

        {:error, {:already_started, agent_pid}} ->
          Agent.update(agent_pid, fn _ -> pid end)
          :ok
      end
    end

    defp get_test_pid do
      try do
        Agent.get(@agent_name, & &1)
      catch
        :exit, _ -> nil
      end
    end

    def start_link(opts) do
      test_pid = get_test_pid()
      GenServer.start_link(__MODULE__, %{test_pid: test_pid, client: Keyword.fetch!(opts, :client)})
    end

    def send_message(pid, msg) do
      GenServer.call(pid, {:send_message, msg})
    end

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call({:send_message, msg}, _from, state) do
      if state.test_pid, do: send(state.test_pid, {:tws_sent, msg})
      {:reply, :ok, state}
    end
  end

  # Wire format helpers: raw wire_id = msg_id + @protobuf_offset (200)
  @open_order_wire_id 205
  @open_orders_end_wire_id 253
  @completed_order_wire_id 301
  @completed_orders_end_wire_id 302
  @order_status_wire_id 203
  @order_bound_wire_id 300
  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  defp start_client_with_next_valid_id(next_valid_id) do
    client = start_client()
    inject_next_valid_id(client, next_valid_id)
    client
  end

  defp inject_next_valid_id(client, next_valid_id) do
    # Simulate TWS sending a NextValidId during the handshake
    proto_payload =
      %Proto.NextValidId{order_id: next_valid_id}
      |> Protobuf.encode()

    wire_msg = <<209::big-integer-size(32), proto_payload::binary>>
    Client.process_message(client, wire_msg)
    # Small sleep to ensure the cast is processed
    Process.sleep(20)
  end

  describe "open_orders/2" do
    test "accumulates OpenOrder responses and returns {:ok, list} on OpenOrdersEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Orders.open_orders(client, timeout: 5_000)
        end)

      Process.sleep(50)

      order_1 = %Proto.OpenOrder{
        order_id: 1,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0},
        order_state: %Proto.OrderState{status: "PreSubmitted"}
      }

      order_2 = %Proto.OpenOrder{
        order_id: 2,
        contract: %Proto.Contract{symbol: "MSFT", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "SELL", total_quantity: "50", order_type: "MKT"},
        order_state: %Proto.OrderState{status: "Submitted"}
      }

      Client.process_message(client, wire_message(@open_order_wire_id, order_1))
      Client.process_message(client, wire_message(@open_order_wire_id, order_2))

      end_marker = %Proto.OpenOrdersEnd{}
      Client.process_message(client, wire_message(@open_orders_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.OpenOrder{order_id: 1} = first
      assert first.contract.symbol == "AAPL"
      assert first.order.action == "BUY"
      assert first.order.total_quantity == "100"
      assert first.order_state.status == "PreSubmitted"

      assert %Proto.OpenOrder{order_id: 2} = second
      assert second.contract.symbol == "MSFT"
      assert second.order.action == "SELL"
      assert second.order_state.status == "Submitted"
    end

    test "returns {:ok, []} when no open orders exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Orders.open_orders(client, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.OpenOrdersEnd{}
      Client.process_message(client, wire_message(@open_orders_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Orders.open_orders(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "all_open_orders/2" do
    test "accumulates OpenOrder responses and returns {:ok, list} on OpenOrdersEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Orders.all_open_orders(client, timeout: 5_000)
        end)

      Process.sleep(50)

      order = %Proto.OpenOrder{
        order_id: 10,
        contract: %Proto.Contract{symbol: "GOOG", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "BUY", total_quantity: "25", order_type: "LMT", lmt_price: 140.0},
        order_state: %Proto.OrderState{status: "PreSubmitted"}
      }

      Client.process_message(client, wire_message(@open_order_wire_id, order))

      end_marker = %Proto.OpenOrdersEnd{}
      Client.process_message(client, wire_message(@open_orders_end_wire_id, end_marker))

      assert {:ok, [%Proto.OpenOrder{} = result]} = Task.await(task, 5_000)
      assert result.order_id == 10
      assert result.contract.symbol == "GOOG"
      assert result.order.total_quantity == "25"
      assert result.order.lmt_price == 140.0
    end

    test "returns {:ok, []} when no open orders exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Orders.all_open_orders(client, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.OpenOrdersEnd{}
      Client.process_message(client, wire_message(@open_orders_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Orders.all_open_orders(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "completed_orders/2" do
    test "accumulates CompletedOrder responses and returns {:ok, list} on CompletedOrdersEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Orders.completed_orders(client, timeout: 5_000)
        end)

      Process.sleep(50)

      completed_1 = %Proto.CompletedOrder{
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 145.0},
        order_state: %Proto.OrderState{status: "Filled"}
      }

      completed_2 = %Proto.CompletedOrder{
        contract: %Proto.Contract{symbol: "TSLA", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "SELL", total_quantity: "50", order_type: "MKT"},
        order_state: %Proto.OrderState{status: "Filled"}
      }

      Client.process_message(client, wire_message(@completed_order_wire_id, completed_1))
      Client.process_message(client, wire_message(@completed_order_wire_id, completed_2))

      end_marker = %Proto.CompletedOrdersEnd{}
      Client.process_message(client, wire_message(@completed_orders_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.CompletedOrder{} = first
      assert first.contract.symbol == "AAPL"
      assert first.order.action == "BUY"
      assert first.order.lmt_price == 145.0
      assert first.order_state.status == "Filled"

      assert %Proto.CompletedOrder{} = second
      assert second.contract.symbol == "TSLA"
      assert second.order.action == "SELL"
      assert second.order_state.status == "Filled"
    end

    test "returns {:ok, []} when no completed orders exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Orders.completed_orders(client, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.CompletedOrdersEnd{}
      Client.process_message(client, wire_message(@completed_orders_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "passes api_only option to the request" do
      client = start_client()

      task =
        Task.async(fn ->
          Orders.completed_orders(client, api_only: true, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.CompletedOrdersEnd{}
      Client.process_message(client, wire_message(@completed_orders_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Orders.completed_orders(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "place/4" do
    test "subscribes to order lifecycle and receives OrderStatus messages" do
      client = start_client_with_next_valid_id(100)

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, ref} = Orders.place(client, proto_contract, proto_order)
      assert is_reference(ref)

      # The allocated order_id should be 100 (from next_valid_id)
      order_status = %Proto.OrderStatus{
        order_id: 100,
        status: "PreSubmitted",
        filled: "0",
        remaining: "100",
        avg_fill_price: 0.0,
        perm_id: 12345,
        parent_id: 0,
        last_fill_price: 0.0,
        client_id: 0,
        why_held: "",
        mkt_cap_price: 0.0
      }

      Client.process_message(client, wire_message(@order_status_wire_id, order_status))

      assert_receive {:ib_ex, ^ref, %Proto.OrderStatus{} = received}, 1_000
      assert received.order_id == 100
      assert received.status == "PreSubmitted"
      assert received.filled == "0"
      assert received.remaining == "100"
      assert received.perm_id == 12345
    end

    test "receives OpenOrder messages through the subscription" do
      client = start_client_with_next_valid_id(100)

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, ref} = Orders.place(client, proto_contract, proto_order)

      open_order = %Proto.OpenOrder{
        order_id: 100,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0},
        order_state: %Proto.OrderState{status: "PreSubmitted"}
      }

      Client.process_message(client, wire_message(@open_order_wire_id, open_order))

      assert_receive {:ib_ex, ^ref, %Proto.OpenOrder{} = received}, 1_000
      assert received.order_id == 100
      assert received.contract.symbol == "AAPL"
      assert received.order.action == "BUY"
    end

    test "receives OrderBound messages through the subscription" do
      client = start_client_with_next_valid_id(100)

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, ref} = Orders.place(client, proto_contract, proto_order)

      order_bound = %Proto.OrderBound{
        order_id: 100,
        client_id: 0,
        perm_id: 98765
      }

      Client.process_message(client, wire_message(@order_bound_wire_id, order_bound))

      assert_receive {:ib_ex, ^ref, %Proto.OrderBound{} = received}, 1_000
      assert received.order_id == 100
      assert received.perm_id == 98765
    end

    test "sends IdsRequest to TWS after placing an order" do
      RecordingConnection.set_test_pid(self())
      {:ok, client} = Client.start_link(connection_handler: RecordingConnection)
      inject_next_valid_id(client, 42)

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "1", order_type: "LMT", lmt_price: 150.0}

      {:ok, _ref} = Orders.place(client, proto_contract, proto_order)

      # First message: the PlaceOrderRequest
      assert_receive {:tws_sent, _place_order_msg}, 1_000

      # Second message: IdsRequest to get the next valid order ID from TWS
      assert_receive {:tws_sent, ids_request_msg}, 1_000
      <<_wire_id::big-integer-size(32), payload::binary>> = ids_request_msg
      decoded = Protobuf.decode(payload, Proto.IdsRequest)
      assert decoded.num_ids == 1
    end

    test "sends the PlaceOrderRequest with order_id from next_valid_id" do
      RecordingConnection.set_test_pid(self())
      {:ok, client} = Client.start_link(connection_handler: RecordingConnection)
      inject_next_valid_id(client, 42)

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, _ref} = Orders.place(client, proto_contract, proto_order)

      assert_receive {:tws_sent, wire_msg}, 1_000
      <<_wire_id::big-integer-size(32), payload::binary>> = wire_msg
      # PlaceOrderRequest wire_id = msg_id + 200
      decoded = Protobuf.decode(payload, Proto.PlaceOrderRequest)
      assert decoded.order_id == 42
      assert decoded.contract.symbol == "AAPL"
      assert decoded.order.action == "BUY"
    end

    test "accepts domain contracts and proto orders" do
      client = start_client_with_next_valid_id(100)

      domain_contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, ref} = Orders.place(client, domain_contract, proto_order)
      assert is_reference(ref)
    end

    test "accepts proto contracts and domain orders" do
      client = start_client_with_next_valid_id(100)

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      domain_order = DomainOrder.new(%{action: "BUY", total_quantity: 100, order_type: "LMT", limit_price: 150.0})

      {:ok, ref} = Orders.place(client, proto_contract, domain_order)
      assert is_reference(ref)
    end

    test "accepts domain contracts and domain orders" do
      client = start_client_with_next_valid_id(100)

      domain_contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      domain_order = DomainOrder.new(%{action: "BUY", total_quantity: 100, order_type: "LMT", limit_price: 150.0})

      {:ok, ref} = Orders.place(client, domain_contract, domain_order)
      assert is_reference(ref)
    end
  end

  describe "cancel/3" do
    test "sends CancelOrderRequest and returns :ok" do
      client = start_client()

      assert :ok = Orders.cancel(client, 42)
    end

    test "accepts options for order cancel parameters" do
      client = start_client()

      assert :ok = Orders.cancel(client, 42, manual_order_cancel_time: "20240101 12:00:00", ext_operator: "ext_op")
    end

    test "sends cancel for different order IDs" do
      client = start_client()

      for order_id <- [1, 10, 100, 9999] do
        assert :ok = Orders.cancel(client, order_id)
      end
    end
  end

  describe "global_cancel/1" do
    test "sends GlobalCancelRequest and returns :ok" do
      client = start_client()

      assert :ok = Orders.global_cancel(client)
    end
  end
end
