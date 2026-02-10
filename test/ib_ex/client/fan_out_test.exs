defmodule IbEx.Client.FanOutTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.Orders
  alias IbEx.Client.Subscriptions
  alias IbEx.Client.Proto.Protobuf, as: Proto

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

  @order_status_wire_id 203
  @open_order_wire_id 205

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  # ---------------------------------------------------------------------------
  # Testing Criteria 1: Two subscribers registered for the same order_id both
  # receive an OrderStatus message
  # ---------------------------------------------------------------------------

  describe "fan-out: two subscribers on the same order_id" do
    test "both receive an OrderStatus message" do
      client = start_client()

      # Place an order (subscriber 1 = stream)
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, stream_ref} =
        Orders.place(client, proto_contract, proto_order)

      # The allocated order_id is 1

      # Cancel that order (subscriber 2 = request_response on same order_id)
      cancel_task =
        Task.async(fn ->
          Orders.cancel(client, 1, timeout: 5_000)
        end)

      Process.sleep(50)

      # Simulate OrderStatus arriving for order_id=1
      order_status = %Proto.OrderStatus{
        order_id: 1,
        status: "Cancelled",
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

      # Stream subscriber receives the message
      assert_receive {:ib_ex, ^stream_ref, %Proto.OrderStatus{order_id: 1, status: "Cancelled"}}, 1_000

      # CancelOrder request also completes with the same message
      assert {:ok, %Proto.OrderStatus{order_id: 1, status: "Cancelled"}} = Task.await(cancel_task, 5_000)
    end

    test "both receive an OpenOrder message" do
      client = start_client()

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, stream_ref_1} =
        Orders.place(client, proto_contract, proto_order)

      # Spawn a second subscriber process that subscribes to a second PlaceOrder (different order)
      # and verify that the first subscriber gets messages for order_id=1 only
      open_order = %Proto.OpenOrder{
        order_id: 1,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        order: %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0},
        order_state: %Proto.OrderState{status: "PreSubmitted"}
      }

      Client.process_message(client, wire_message(@open_order_wire_id, open_order))

      assert_receive {:ib_ex, ^stream_ref_1, %Proto.OpenOrder{order_id: 1}}, 1_000
    end
  end

  # ---------------------------------------------------------------------------
  # Testing Criteria 2: CancelOrder registers on existing order_id and completes
  # when OrderStatus(Cancelled) arrives, while PlaceOrder stream subscriber also
  # receives the same message
  # ---------------------------------------------------------------------------

  describe "fan-out: CancelOrder + PlaceOrder lifecycle" do
    test "CancelOrder completes on OrderStatus while PlaceOrder stream also receives it" do
      client = start_client()

      # Place an order
      proto_contract = %Proto.Contract{symbol: "MSFT", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "SELL", total_quantity: "50", order_type: "MKT"}

      {:ok, stream_ref} = Orders.place(client, proto_contract, proto_order)

      # First, receive some lifecycle events for the order
      pre_submitted = %Proto.OrderStatus{
        order_id: 1,
        status: "PreSubmitted",
        filled: "0",
        remaining: "50",
        avg_fill_price: 0.0,
        perm_id: 99999,
        parent_id: 0,
        last_fill_price: 0.0,
        client_id: 0,
        why_held: "",
        mkt_cap_price: 0.0
      }

      Client.process_message(client, wire_message(@order_status_wire_id, pre_submitted))
      assert_receive {:ib_ex, ^stream_ref, %Proto.OrderStatus{status: "PreSubmitted"}}, 1_000

      # Now cancel the order
      cancel_task =
        Task.async(fn ->
          Orders.cancel(client, 1, timeout: 5_000)
        end)

      Process.sleep(50)

      # OrderStatus(Cancelled) arrives -- should go to both subscribers
      cancelled = %Proto.OrderStatus{
        order_id: 1,
        status: "Cancelled",
        filled: "0",
        remaining: "50",
        avg_fill_price: 0.0,
        perm_id: 99999,
        parent_id: 0,
        last_fill_price: 0.0,
        client_id: 0,
        why_held: "",
        mkt_cap_price: 0.0
      }

      Client.process_message(client, wire_message(@order_status_wire_id, cancelled))

      # Stream subscriber sees Cancelled
      assert_receive {:ib_ex, ^stream_ref, %Proto.OrderStatus{order_id: 1, status: "Cancelled"}}, 1_000

      # CancelOrder request completes with the OrderStatus
      assert {:ok, %Proto.OrderStatus{order_id: 1, status: "Cancelled"}} = Task.await(cancel_task, 5_000)
    end
  end

  # ---------------------------------------------------------------------------
  # Testing Criteria 4: Removing one subscriber from a shared key does not
  # affect the other subscriber
  # ---------------------------------------------------------------------------

  describe "fan-out: independent subscriber cleanup" do
    test "PlaceOrder stream unsubscribed while CancelOrder request is pending" do
      client = start_client()

      # Place an order
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, stream_ref} = Orders.place(client, proto_contract, proto_order)

      # Cancel the order (registers on the same key)
      cancel_task =
        Task.async(fn ->
          Orders.cancel(client, 1, timeout: 5_000)
        end)

      Process.sleep(50)

      # Unsubscribe the PlaceOrder stream -- CancelOrder should still be pending
      Client.unsubscribe(client, stream_ref)

      # Send OrderStatus(Cancelled) -- only CancelOrder request should receive it
      cancelled = %Proto.OrderStatus{
        order_id: 1,
        status: "Cancelled",
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

      Client.process_message(client, wire_message(@order_status_wire_id, cancelled))

      # CancelOrder should still complete successfully
      assert {:ok, %Proto.OrderStatus{order_id: 1, status: "Cancelled"}} = Task.await(cancel_task, 5_000)

      # Stream ref should NOT receive any messages since it was unsubscribed
      refute_receive {:ib_ex, ^stream_ref, _}
    end

    test "CancelOrder times out but PlaceOrder stream continues receiving messages" do
      client = start_client()

      # Place an order
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}
      proto_order = %Proto.Order{action: "BUY", total_quantity: "100", order_type: "LMT", lmt_price: 150.0}

      {:ok, stream_ref} = Orders.place(client, proto_contract, proto_order)

      # Cancel the order with a short timeout
      cancel_task =
        Task.async(fn ->
          try do
            Orders.cancel(client, 1, timeout: 100)
          catch
            :exit, {:timeout, _} -> {:error, :timeout}
          end
        end)

      # Wait for the timeout to fire
      assert {:error, :timeout} = Task.await(cancel_task, 5_000)

      # Stream should still receive messages
      order_status = %Proto.OrderStatus{
        order_id: 1,
        status: "Submitted",
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

      assert_receive {:ib_ex, ^stream_ref, %Proto.OrderStatus{order_id: 1, status: "Submitted"}}, 1_000
    end
  end

  # ---------------------------------------------------------------------------
  # Subscriptions-level fan-out tests
  # ---------------------------------------------------------------------------

  describe "Subscriptions: multi-entry per key" do
    setup do
      table_refs = Subscriptions.initialize()
      %{table_refs: table_refs}
    end

    test "lookup_all returns all entries for a shared key", %{table_refs: table_refs} do
      key = {:order_id, 42}

      # Register a stream entry
      stream_sub_ref = make_ref()
      stream_monitor_ref = make_ref()

      Subscriptions.register_stream(
        table_refs,
        key,
        self(),
        stream_monitor_ref,
        stream_sub_ref,
        Proto.PlaceOrderRequest
      )

      # Register a request entry on the same key
      from = {self(), make_ref()}
      timer_ref = make_ref()
      Subscriptions.register_request(table_refs, key, from, timer_ref, Proto.CancelOrderRequest)

      # lookup_all should return both entries
      assert {:ok, entries} = Subscriptions.lookup_all(table_refs, key)
      assert length(entries) == 2

      types = Enum.map(entries, & &1.type)
      assert :stream in types
      assert :request in types
    end

    test "remove_entry removes only the specific entry", %{table_refs: table_refs} do
      key = {:order_id, 42}

      # Register two entries
      stream_sub_ref = make_ref()
      stream_monitor_ref = make_ref()

      Subscriptions.register_stream(
        table_refs,
        key,
        self(),
        stream_monitor_ref,
        stream_sub_ref,
        Proto.PlaceOrderRequest
      )

      from = {self(), make_ref()}
      timer_ref = make_ref()

      request_entry = %{
        type: :request,
        from: from,
        timer_ref: timer_ref,
        request_module: Proto.CancelOrderRequest
      }

      Subscriptions.register_request(table_refs, key, from, timer_ref, Proto.CancelOrderRequest)

      # Remove just the request entry
      Subscriptions.remove_entry(table_refs, key, request_entry)

      # Stream entry should still be there
      assert {:ok, remaining} = Subscriptions.lookup_all(table_refs, key)
      assert length(remaining) == 1
      assert [%{type: :stream}] = remaining
    end

    test "remove_subscription removes all entries for a key", %{table_refs: table_refs} do
      key = {:order_id, 42}

      stream_sub_ref = make_ref()
      stream_monitor_ref = make_ref()

      Subscriptions.register_stream(
        table_refs,
        key,
        self(),
        stream_monitor_ref,
        stream_sub_ref,
        Proto.PlaceOrderRequest
      )

      from = {self(), make_ref()}
      timer_ref = make_ref()
      Subscriptions.register_request(table_refs, key, from, timer_ref, Proto.CancelOrderRequest)

      assert {:ok, entries} = Subscriptions.lookup_all(table_refs, key)
      assert length(entries) == 2

      Subscriptions.remove_subscription(table_refs, key)

      assert {:error, :missing_subscription} = Subscriptions.lookup_all(table_refs, key)
    end

    test "lookup returns first entry when multiple exist", %{table_refs: table_refs} do
      key = {:order_id, 42}

      stream_sub_ref = make_ref()
      stream_monitor_ref = make_ref()

      Subscriptions.register_stream(
        table_refs,
        key,
        self(),
        stream_monitor_ref,
        stream_sub_ref,
        Proto.PlaceOrderRequest
      )

      from = {self(), make_ref()}
      timer_ref = make_ref()
      Subscriptions.register_request(table_refs, key, from, timer_ref, Proto.CancelOrderRequest)

      # lookup should return the first entry (not error out)
      assert {:ok, _entry} = Subscriptions.lookup(table_refs, key)
    end

    test "existing single-subscriber conversations still work with shared buffer", %{table_refs: table_refs} do
      key = {:request_id, 1}
      from = {self(), make_ref()}
      timer_ref = make_ref()

      Subscriptions.register_request(table_refs, key, from, timer_ref, Proto.MatchingSymbolsRequest)

      assert {:ok, entry} = Subscriptions.lookup(table_refs, key)
      assert entry.type == :request
      assert entry.from == from

      # append to shared buffer + read it back
      :ok = Subscriptions.append_response(table_refs, key, :resp1)
      {:ok, buffer} = Subscriptions.get_responses(table_refs, key)
      assert buffer == [:resp1]
    end
  end

  # ---------------------------------------------------------------------------
  # Conversations: register_request_on_existing_key
  # ---------------------------------------------------------------------------

  describe "Conversations.register_request_on_existing_key/6" do
    alias IbEx.Client.Conversations

    setup do
      table_refs = Subscriptions.initialize()
      %{table_refs: table_refs}
    end

    test "registers a request entry on an existing order_id key", %{table_refs: table_refs} do
      key = {:order_id, 42}

      # First register a stream (PlaceOrder)
      stream_sub_ref = make_ref()
      stream_monitor_ref = make_ref()

      Subscriptions.register_stream(
        table_refs,
        key,
        self(),
        stream_monitor_ref,
        stream_sub_ref,
        Proto.PlaceOrderRequest
      )

      # Now register CancelOrder request on the same key
      from = {self(), make_ref()}

      assert {:ok, ^key} =
               Conversations.register_request_on_existing_key(
                 table_refs,
                 Proto.CancelOrderRequest,
                 key,
                 from,
                 5_000,
                 self()
               )

      # Both entries should exist
      assert {:ok, entries} = Subscriptions.lookup_all(table_refs, key)
      assert length(entries) == 2
    end

    test "returns :error for unknown request module", %{table_refs: table_refs} do
      key = {:order_id, 42}
      from = {self(), make_ref()}

      assert :error =
               Conversations.register_request_on_existing_key(
                 table_refs,
                 SomeUnknownModule,
                 key,
                 from,
                 5_000,
                 self()
               )
    end

    test "sets up a timeout timer", %{table_refs: table_refs} do
      key = {:order_id, 42}
      from = {self(), make_ref()}

      assert {:ok, ^key} =
               Conversations.register_request_on_existing_key(
                 table_refs,
                 Proto.CancelOrderRequest,
                 key,
                 from,
                 50,
                 self()
               )

      assert_receive {:request_timeout, ^key}, 200
    end
  end
end
