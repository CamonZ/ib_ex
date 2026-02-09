defmodule IbEx.ClientTest do
  use ExUnit.Case, async: true

  defmodule MockSuccessConnection do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, [])
    end

    @impl true
    def init(arg) do
      {:ok, arg}
    end

    def send_message(_pid, _msg) do
      :ok
    end

    @impl true
    def handle_call(_, _, state) do
      {:reply, :ok, state}
    end
  end

  defmodule MockFailedConnection do
    def start_link(_) do
      {:error, :timeout}
    end
  end

  defmodule MockRecordingConnection do
    use GenServer

    def start_link(opts) do
      test_pid = Keyword.fetch!(opts, :client)
      GenServer.start_link(__MODULE__, %{test_pid: test_pid})
    end

    @impl true
    def init(state) do
      {:ok, state}
    end

    def send_message(pid, msg) do
      GenServer.call(pid, {:send_message, msg})
    end

    @impl true
    def handle_call({:send_message, msg}, _from, state) do
      send(state.test_pid, {:tws_sent, msg})
      {:reply, :ok, state}
    end
  end

  alias IbEx.Client
  alias IbEx.Client.Subscriptions

  describe "init/1" do
    test "opens the connection to IBKR's TWS or Gateway and creates the message subscriptions table" do
      assert {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      assert is_pid(state.connection)
      assert Process.alive?(state.connection)

      refute is_nil(state.subscriptions_table_ref)

      assert :ets.lookup(state.subscriptions_table_ref, :message_request_ids) == [message_request_ids: 1]
    end

    test "stops the server on failure to open the connection" do
      assert {:stop, {:connection_error, {:error, :timeout}}} = Client.init(connection_handler: MockFailedConnection)
    end
  end

  describe "handle_cast/2 when processing an incoming message" do
    test "updates the client's state with the server version, the connection timestamp and continues to validate the server version" do
      initial_state = %{status: :connecting, trace_messages: false}

      str = "213\x0020240605 17:25:52 Central European Standard Time\x00"

      assert {:noreply, new_state, continuation} = Client.handle_cast({:process_message, str}, initial_state)

      assert new_state.server_version == 213
      assert new_state.connection_timestamp == ~N[2024-06-05 17:25:52]
      assert new_state.status == :connected

      assert continuation == {:continue, :validate_server_version}
    end

    @tag capture_log: true
    test "relays the msg when there's a subscription for said message" do
      table_ref = Subscriptions.initialize()

      # Build a protobuf ManagedAccounts message (msg_id=15, wire_id=215)
      proto_payload =
        %IbEx.Client.Proto.Protobuf.ManagedAccounts{accounts_list: "DU123456,DU789012"}
        |> Protobuf.encode()

      wire_msg = <<215::big-integer-size(32), proto_payload::binary>>

      state = %{
        subscriptions_table_ref: table_ref,
        status: :connected,
        trace_messages: false
      }

      assert {:noreply, %{managed_accounts: "DU123456,DU789012"}} =
               Client.handle_cast({:process_message, wire_msg}, state)
    end
  end

  describe "handle_continue(:validate_server_version)" do
    test "continues to :request_start_api when server_version meets minimum (213)" do
      state = %IbEx.Client{server_version: 213}

      assert {:noreply, ^state, {:continue, :request_start_api}} =
               Client.handle_continue(:validate_server_version, state)
    end

    test "stops the process when server_version is below minimum (213)" do
      state = %IbEx.Client{server_version: 178}

      assert {:stop, {:required_version_unmet, :protobuf_rest_messages_3, 178}} =
               Client.handle_continue(:validate_server_version, state)
    end
  end

  describe "request/3 :request_response path" do
    test "returns {:ok, response} immediately on single response" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest{pattern: "AAPL"}
      from = {self(), make_ref()}

      assert {:noreply, ^state} = Client.handle_call({:request, proto_msg, []}, from, state)

      # Verify ETS entry was created with req_id {:request_id, 1}
      assert {:ok, %{type: :request, request_module: IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest}} =
               Subscriptions.lookup(table_ref, {:request_id, 1})

      # Simulate receiving a SymbolSamples response with req_id=1
      response = %IbEx.Client.Proto.Protobuf.SymbolSamples{req_id: 1, contract_descriptions: []}

      proto_payload = Protobuf.encode(response)
      wire_msg = <<279::big-integer-size(32), proto_payload::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      # The caller should receive the reply
      assert_receive {_ref, {:ok, %IbEx.Client.Proto.Protobuf.SymbolSamples{req_id: 1}}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, {:request_id, 1})
    end
  end

  describe "request/3 :bounded_stream path" do
    test "accumulates multiple responses and returns {:ok, list} on end marker" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.ContractDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      from = {self(), make_ref()}

      assert {:noreply, ^state} = Client.handle_call({:request, proto_msg, []}, from, state)

      # Verify ETS entry
      assert {:ok, %{type: :request, request_module: IbEx.Client.Proto.Protobuf.ContractDataRequest}} =
               Subscriptions.lookup(table_ref, {:request_id, 1})

      # Simulate receiving two ContractData responses (msg_id=10, wire_id=210)
      contract_data_1 = %IbEx.Client.Proto.Protobuf.ContractData{req_id: 1}
      wire_msg_1 = <<210::big-integer-size(32), Protobuf.encode(contract_data_1)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg_1}, state)

      # Should not have replied yet
      refute_receive {_ref, {:ok, _}}

      contract_data_2 = %IbEx.Client.Proto.Protobuf.ContractData{req_id: 1}
      wire_msg_2 = <<210::big-integer-size(32), Protobuf.encode(contract_data_2)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg_2}, state)

      # Still not replied
      refute_receive {_ref, {:ok, _}}

      # Simulate receiving ContractDataEnd (msg_id=52, wire_id=252)
      end_marker = %IbEx.Client.Proto.Protobuf.ContractDataEnd{req_id: 1}
      wire_end = <<252::big-integer-size(32), Protobuf.encode(end_marker)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_end}, state)

      # Now the caller should receive the accumulated buffer
      assert_receive {_ref, {:ok, buffer}}
      assert length(buffer) == 2
      assert Enum.all?(buffer, &match?(%IbEx.Client.Proto.Protobuf.ContractData{req_id: 1}, &1))

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, {:request_id, 1})
    end
  end

  describe "request/3 error routing" do
    test "ErrorMessage with id > 0 replies {:error, error} to conversation owner and cleans up" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest{pattern: "AAPL"}
      from = {self(), make_ref()}

      assert {:noreply, ^state} = Client.handle_call({:request, proto_msg, []}, from, state)

      # Verify ETS entry exists
      assert {:ok, %{type: :request}} = Subscriptions.lookup(table_ref, {:request_id, 1})

      # Simulate receiving an ErrorMessage with id=1 (msg_id=4, wire_id=204)
      error_proto = %IbEx.Client.Proto.Protobuf.ErrorMessage{id: 1, error_code: 200, error_msg: "No security found"}
      wire_msg = <<204::big-integer-size(32), Protobuf.encode(error_proto)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      # Caller should receive {:error, %Types.Error{}}
      assert_receive {_ref, {:error, %IbEx.Client.Types.Error{id: 1, code: 200, message: "No security found"}}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, {:request_id, 1})
    end
  end

  describe "request/3 timeout path" do
    test "replies {:error, :timeout} when no response arrives and cleans up ETS" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest{pattern: "AAPL"}
      from = {self(), make_ref()}

      assert {:noreply, ^state} =
               Client.handle_call({:request, proto_msg, [timeout: 100]}, from, state)

      # Verify ETS entry exists
      assert {:ok, %{type: :request}} = Subscriptions.lookup(table_ref, {:request_id, 1})

      # Simulate the timeout firing
      assert {:noreply, ^state} = Client.handle_info({:request_timeout, {:request_id, 1}}, state)

      # Caller should receive {:error, :timeout}
      assert_receive {_ref, {:error, :timeout}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, {:request_id, 1})
    end

    test "timeout is a no-op when conversation already completed" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      # No ETS entry for key {:request_id, 999} -- already completed
      assert {:noreply, ^state} = Client.handle_info({:request_timeout, {:request_id, 999}}, state)
    end
  end

  describe "subscribe/3" do
    test "returns {:ok, subscription_ref} and registers a stream entry in ETS" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.MarketDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      assert {:reply, {:ok, subscription_ref}, ^state} =
               Client.handle_call({:subscribe, self(), proto_msg, []}, {self(), make_ref()}, state)

      assert is_reference(subscription_ref)

      # Verify ETS entry was created as a :stream type with key {:request_id, 1}
      assert {:ok, entry} = Subscriptions.lookup(table_ref, {:request_id, 1})
      assert entry.type == :stream
      assert entry.subscriber == self()
      assert entry.subscription_ref == subscription_ref
      assert entry.request_module == IbEx.Client.Proto.Protobuf.MarketDataRequest
      assert is_reference(entry.monitor_ref)
    end

    test "returns {:error, :unknown_conversation} for non-stream conversation types" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      # MatchingSymbolsRequest is :request_response, not :stream
      proto_msg = %IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest{pattern: "AAPL"}

      assert {:reply, {:error, :unknown_conversation}, ^state} =
               Client.handle_call({:subscribe, self(), proto_msg, []}, {self(), make_ref()}, state)
    end
  end

  describe "stream message delivery" do
    test "delivers TickPrice messages as {:ib_ex, ref, msg} via send/2" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      proto_msg = %IbEx.Client.Proto.Protobuf.MarketDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      {:reply, {:ok, subscription_ref}, ^state} =
        Client.handle_call({:subscribe, self(), proto_msg, []}, {self(), make_ref()}, state)

      # Simulate receiving a TickPrice response with req_id=1 (msg_id=1, wire_id=201)
      tick_price = %IbEx.Client.Proto.Protobuf.TickPrice{req_id: 1, tick_type: 4, price: 150.25}
      wire_msg = <<201::big-integer-size(32), Protobuf.encode(tick_price)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      assert_receive {:ib_ex, ^subscription_ref,
                      %IbEx.Client.Proto.Protobuf.TickPrice{req_id: 1, tick_type: 4, price: 150.25}}
    end

    test "delivers multiple messages continuously without consuming the subscription" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.MarketDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      {:reply, {:ok, subscription_ref}, ^state} =
        Client.handle_call({:subscribe, self(), proto_msg, []}, {self(), make_ref()}, state)

      # Send first tick
      tick_1 = %IbEx.Client.Proto.Protobuf.TickPrice{req_id: 1, tick_type: 4, price: 150.25}
      wire_1 = <<201::big-integer-size(32), Protobuf.encode(tick_1)::binary>>
      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_1}, state)

      assert_receive {:ib_ex, ^subscription_ref, %IbEx.Client.Proto.Protobuf.TickPrice{price: 150.25}}

      # Send second tick -- subscription should still be active
      tick_2 = %IbEx.Client.Proto.Protobuf.TickPrice{req_id: 1, tick_type: 4, price: 151.00}
      wire_2 = <<201::big-integer-size(32), Protobuf.encode(tick_2)::binary>>
      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_2}, state)

      assert_receive {:ib_ex, ^subscription_ref, %IbEx.Client.Proto.Protobuf.TickPrice{price: 151.00}}

      # ETS entry should still exist
      assert {:ok, %{type: :stream}} = Subscriptions.lookup(table_ref, {:request_id, 1})
    end

    test "delivers error messages to stream subscribers" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      proto_msg = %IbEx.Client.Proto.Protobuf.MarketDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      {:reply, {:ok, subscription_ref}, ^state} =
        Client.handle_call({:subscribe, self(), proto_msg, []}, {self(), make_ref()}, state)

      # Simulate receiving an ErrorMessage with id=1 (msg_id=4, wire_id=204)
      error_proto = %IbEx.Client.Proto.Protobuf.ErrorMessage{
        id: 1,
        error_code: 354,
        error_msg: "Requested market data is not subscribed."
      }

      wire_msg = <<204::big-integer-size(32), Protobuf.encode(error_proto)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      assert_receive {:ib_ex, ^subscription_ref,
                      {:error,
                       %IbEx.Client.Types.Error{id: 1, code: 354, message: "Requested market data is not subscribed."}}}
    end
  end

  describe "unsubscribe/2" do
    test "sends CancelMarketData to TWS, demonitors, and cleans up ETS" do
      {:ok, state} = Client.init(connection_handler: MockRecordingConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.MarketDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      {:reply, {:ok, subscription_ref}, ^state} =
        Client.handle_call({:subscribe, self(), proto_msg, []}, {self(), make_ref()}, state)

      # Drain the subscribe request that was sent to TWS
      assert_receive {:tws_sent, _subscribe_msg}

      # Verify ETS entry exists
      assert {:ok, %{type: :stream, monitor_ref: monitor_ref}} =
               Subscriptions.lookup(table_ref, {:request_id, 1})

      # Unsubscribe
      assert {:reply, :ok, ^state} =
               Client.handle_call({:unsubscribe, subscription_ref}, {self(), make_ref()}, state)

      # Verify CancelMarketData was sent to TWS
      assert_receive {:tws_sent, cancel_msg}

      # Decode the cancel message: 4-byte wire_id header + protobuf payload
      <<wire_id::big-integer-size(32), payload::binary>> = cancel_msg
      # CancelMarketData msg_id=2, wire_id=202
      assert wire_id == 202
      decoded = Protobuf.decode(payload, IbEx.Client.Proto.Protobuf.CancelMarketData)
      assert decoded.req_id == 1

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, {:request_id, 1})

      # Monitor should have been removed (verify by checking it's not a valid monitor)
      refute Process.read_timer(monitor_ref)
    end

    test "returns {:error, :not_found} for unknown subscription ref" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      unknown_ref = make_ref()

      assert {:reply, {:error, :not_found}, ^state} =
               Client.handle_call({:unsubscribe, unknown_ref}, {self(), make_ref()}, state)
    end

    test "stops message delivery after unsubscribe" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      proto_msg = %IbEx.Client.Proto.Protobuf.MarketDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      {:reply, {:ok, subscription_ref}, ^state} =
        Client.handle_call({:subscribe, self(), proto_msg, []}, {self(), make_ref()}, state)

      # Unsubscribe
      assert {:reply, :ok, ^state} =
               Client.handle_call({:unsubscribe, subscription_ref}, {self(), make_ref()}, state)

      # Simulate receiving a TickPrice -- should not be delivered
      tick = %IbEx.Client.Proto.Protobuf.TickPrice{req_id: 1, tick_type: 4, price: 150.25}
      wire_msg = <<201::big-integer-size(32), Protobuf.encode(tick)::binary>>
      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      refute_receive {:ib_ex, _, _}
    end
  end

  describe "subscriber death cleanup" do
    test "handle_info(:DOWN) sends cancel to TWS and cleans up ETS when subscriber dies" do
      {:ok, state} = Client.init(connection_handler: MockRecordingConnection)
      table_ref = state.subscriptions_table_ref

      # Spawn a subscriber process that we can kill
      subscriber = spawn(fn -> Process.sleep(:infinity) end)
      # Monitor it from test process so we can confirm death
      test_monitor = Process.monitor(subscriber)

      proto_msg = %IbEx.Client.Proto.Protobuf.MarketDataRequest{
        contract: %IbEx.Client.Proto.Protobuf.Contract{symbol: "AAPL"}
      }

      {:reply, {:ok, _subscription_ref}, ^state} =
        Client.handle_call({:subscribe, subscriber, proto_msg, []}, {self(), make_ref()}, state)

      # Drain the subscribe request sent to TWS
      assert_receive {:tws_sent, _subscribe_msg}

      # Verify ETS entry exists and grab the monitor ref
      assert {:ok, %{type: :stream, monitor_ref: monitor_ref}} =
               Subscriptions.lookup(table_ref, {:request_id, 1})

      # Kill the subscriber and wait for confirmation
      Process.exit(subscriber, :kill)
      assert_receive {:DOWN, ^test_monitor, :process, ^subscriber, :killed}

      # The handle_call(:subscribe) also set up a monitor, so flush that :DOWN from our mailbox
      # (since handle_call runs in test process context, that monitor fires here too)
      receive do
        {:DOWN, ^monitor_ref, :process, ^subscriber, :killed} -> :ok
      after
        100 -> :ok
      end

      # Simulate the :DOWN message that the Client GenServer would receive
      assert {:noreply, ^state} =
               Client.handle_info({:DOWN, monitor_ref, :process, subscriber, :killed}, state)

      # Verify CancelMarketData was sent to TWS
      assert_receive {:tws_sent, cancel_msg}
      <<wire_id::big-integer-size(32), payload::binary>> = cancel_msg
      assert wire_id == 202
      decoded = Protobuf.decode(payload, IbEx.Client.Proto.Protobuf.CancelMarketData)
      assert decoded.req_id == 1

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, {:request_id, 1})
    end

    test "handle_info(:DOWN) is a no-op for unknown monitor refs" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      unknown_monitor = make_ref()

      assert {:noreply, ^state} =
               Client.handle_info({:DOWN, unknown_monitor, :process, self(), :normal}, state)
    end
  end

  describe "request/3 global correlation :request_response path" do
    test "returns {:ok, response} for CurrentTimeRequest (no req_id)" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.CurrentTimeRequest{}
      from = {self(), make_ref()}

      assert {:noreply, ^state} = Client.handle_call({:request, proto_msg, []}, from, state)

      # Verify ETS entry was created with global key
      global_key = {:global, IbEx.Client.Proto.Protobuf.CurrentTimeRequest}

      assert {:ok, %{type: :request, request_module: IbEx.Client.Proto.Protobuf.CurrentTimeRequest}} =
               Subscriptions.lookup(table_ref, global_key)

      # Simulate receiving a CurrentTime response (msg_id=49, wire_id=249) -- no req_id field
      response = %IbEx.Client.Proto.Protobuf.CurrentTime{current_time: 1_700_000_000}
      proto_payload = Protobuf.encode(response)
      wire_msg = <<249::big-integer-size(32), proto_payload::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      # The caller should receive the reply
      assert_receive {_ref, {:ok, %IbEx.Client.Proto.Protobuf.CurrentTime{current_time: 1_700_000_000}}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, global_key)
    end
  end

  describe "request/3 global correlation :bounded_stream path" do
    test "accumulates OpenOrder responses and returns buffer on OpenOrdersEnd" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.OpenOrdersRequest{}
      from = {self(), make_ref()}

      assert {:noreply, ^state} = Client.handle_call({:request, proto_msg, []}, from, state)

      # Verify ETS entry was created with global key
      global_key = {:global, IbEx.Client.Proto.Protobuf.OpenOrdersRequest}

      assert {:ok, %{type: :request, request_module: IbEx.Client.Proto.Protobuf.OpenOrdersRequest}} =
               Subscriptions.lookup(table_ref, global_key)

      # Simulate receiving an OpenOrder response (msg_id=5, wire_id=205) -- no req_id field
      open_order = %IbEx.Client.Proto.Protobuf.OpenOrder{order_id: 1}
      wire_msg = <<205::big-integer-size(32), Protobuf.encode(open_order)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      # Should not have replied yet
      refute_receive {_ref, {:ok, _}}

      # Simulate receiving OpenOrdersEnd (msg_id=53, wire_id=253) -- no req_id
      end_marker = %IbEx.Client.Proto.Protobuf.OpenOrdersEnd{}
      wire_end = <<253::big-integer-size(32), Protobuf.encode(end_marker)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_end}, state)

      # Now the caller should receive the accumulated buffer
      assert_receive {_ref, {:ok, buffer}}
      assert length(buffer) == 1
      assert [%IbEx.Client.Proto.Protobuf.OpenOrder{order_id: 1}] = buffer

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, global_key)
    end

    test "global correlation timeout fires and cleans up" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      table_ref = state.subscriptions_table_ref

      proto_msg = %IbEx.Client.Proto.Protobuf.OpenOrdersRequest{}
      from = {self(), make_ref()}

      assert {:noreply, ^state} =
               Client.handle_call({:request, proto_msg, [timeout: 100]}, from, state)

      global_key = {:global, IbEx.Client.Proto.Protobuf.OpenOrdersRequest}
      assert {:ok, %{type: :request}} = Subscriptions.lookup(table_ref, global_key)

      # Simulate the timeout firing
      assert {:noreply, ^state} = Client.handle_info({:request_timeout, global_key}, state)

      # Caller should receive {:error, :timeout}
      assert_receive {_ref, {:error, :timeout}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, global_key)
    end
  end
end
