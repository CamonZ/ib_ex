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

      # Verify ETS entry was created with req_id "1"
      assert {:ok, %{type: :request, request_module: IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest}} =
               Subscriptions.lookup(table_ref, "1")

      # Simulate receiving a SymbolSamples response with req_id=1
      response = %IbEx.Client.Proto.Protobuf.SymbolSamples{req_id: 1, contract_descriptions: []}

      proto_payload = Protobuf.encode(response)
      wire_msg = <<279::big-integer-size(32), proto_payload::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      # The caller should receive the reply
      assert_receive {_ref, {:ok, %IbEx.Client.Proto.Protobuf.SymbolSamples{req_id: 1}}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, "1")
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
               Subscriptions.lookup(table_ref, "1")

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
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, "1")
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
      assert {:ok, %{type: :request}} = Subscriptions.lookup(table_ref, "1")

      # Simulate receiving an ErrorMessage with id=1 (msg_id=4, wire_id=204)
      error_proto = %IbEx.Client.Proto.Protobuf.ErrorMessage{id: 1, error_code: 200, error_msg: "No security found"}
      wire_msg = <<204::big-integer-size(32), Protobuf.encode(error_proto)::binary>>

      assert {:noreply, ^state} = Client.handle_cast({:process_message, wire_msg}, state)

      # Caller should receive {:error, %Types.Error{}}
      assert_receive {_ref, {:error, %IbEx.Client.Types.Error{id: 1, code: 200, message: "No security found"}}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, "1")
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
      assert {:ok, %{type: :request}} = Subscriptions.lookup(table_ref, "1")

      # Simulate the timeout firing
      assert {:noreply, ^state} = Client.handle_info({:request_timeout, "1"}, state)

      # Caller should receive {:error, :timeout}
      assert_receive {_ref, {:error, :timeout}}

      # ETS entry should be cleaned up
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, "1")
    end

    test "timeout is a no-op when conversation already completed" do
      {:ok, state} = Client.init(connection_handler: MockSuccessConnection)

      # No ETS entry for key "999" -- already completed
      assert {:noreply, ^state} = Client.handle_info({:request_timeout, "999"}, state)
    end
  end
end
