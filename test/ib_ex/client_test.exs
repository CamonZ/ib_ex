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
  alias IbEx.Client.Messages.MatchingSymbols.Request
  alias IbEx.Client.Subscriptions

  alias __MODULE__.MockSuccessConnection
  alias __MODULE__.MockFailedConnection

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
      Subscriptions.subscribe_by_request_id(table_ref, self())

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

  describe "handle_cast/2 when sending an outgoing message" do
    test "subscribes the message's responses to the subscriptions mapping" do
      assert {:ok, msg} = Request.new("AAPL")

      assert {:ok, state} = Client.init(connection_handler: MockSuccessConnection)
      assert {:noreply, ^state} = Client.handle_cast({:send_request, self(), msg}, state)

      assert [{"1", pid}] = :ets.lookup(state.subscriptions_table_ref, "1")
      assert pid == self()
    end
  end
end
