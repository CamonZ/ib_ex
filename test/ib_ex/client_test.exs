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
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.ContractDescription
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
      initial_state = %{status: :connecting}

      str = "178\x0020240605 17:25:52 Central European Standard Time\x00"

      assert {:noreply, new_state, continuation} = Client.handle_cast({:process_message, str}, initial_state)

      assert new_state.server_version == 178
      assert new_state.connection_timestamp == ~N[2024-06-05 17:25:52]
      assert new_state.status == :connected

      assert continuation == {:continue, :validate_server_version}
    end

    @symbol_samples_msg_str <<55, 57, 0, 49, 0, 49, 55, 0, 50, 54, 53, 53, 57, 56, 0, 65, 65, 80, 76, 0, 83, 84, 75, 0,
                              78, 65, 83, 68, 65, 81, 0, 85, 83, 68, 0, 53, 0, 67, 70, 68, 0, 79, 80, 84, 0, 73, 79, 80,
                              84, 0, 87, 65, 82, 0, 66, 65, 71, 0, 65, 80, 80, 76, 69, 32, 73, 78, 67, 0, 0, 52, 57, 51,
                              53, 52, 54, 48, 52, 56, 0, 65, 65, 80, 76, 0, 83, 84, 75, 0, 76, 83, 69, 69, 84, 70, 0,
                              71, 66, 80, 0, 48, 0, 76, 83, 32, 49, 88, 32, 65, 65, 80, 76, 0, 0>>

    @tag capture_log: true
    test "relays the msg when there's a subscription for said message" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      state = %{
        subscriptions_table_ref: table_ref,
        status: :connected
      }

      assert {:noreply, ^state} = Client.handle_cast({:process_message, @symbol_samples_msg_str}, state)

      assert_received {:"$gen_cast", {:message_received, msg}}

      assert msg.request_id == "1"
      assert length(msg.contracts) == 2

      first_contract = List.first(msg.contracts)

      assert first_contract == %ContractDescription{
               contract: %Contract{
                 conid: "265598",
                 symbol: "AAPL",
                 security_type: "STK",
                 currency: "USD",
                 primary_exchange: "NASDAQ",
                 description: "APPLE INC",
                 issuer_id: ""
               },
               derivative_security_types: ["CFD", "OPT", "IOPT", "WAR", "BAG"]
             }
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
