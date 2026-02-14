defmodule IbEx.AccountStateManagerTest do
  use ExUnit.Case, async: true

  alias IbEx.AccountStateManager
  alias IbEx.Client.Proto.Protobuf, as: Proto

  # ---------------------------------------------------------------------------
  # Mock Client
  # ---------------------------------------------------------------------------

  defmodule MockClient do
    @moduledoc """
    A mock IbEx.Client GenServer that simulates TWS responses for account data.

    Handles the `subscribe_global` and `request` calls that the
    AccountStateManager makes, and supports injecting streaming updates
    via `send_streaming_update/2`.
    """
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    @doc """
    Sends a streaming update to the subscriber registered via subscribe_global.
    """
    def send_streaming_update(client, msg) do
      GenServer.call(client, {:send_streaming_update, msg})
    end

    @impl true
    def init(opts) do
      initial_data = Keyword.get(opts, :initial_data, [])
      request_error = Keyword.get(opts, :request_error, nil)

      {:ok,
       %{
         initial_data: initial_data,
         request_error: request_error,
         global_subscriptions: %{}
       }}
    end

    @impl true
    def handle_call({:subscribe_global, subscriber, request_module}, _from, state) do
      subscription_ref = make_ref()
      entry = %{subscriber: subscriber, subscription_ref: subscription_ref}
      global_subs = Map.put(state.global_subscriptions, request_module, entry)
      {:reply, {:ok, subscription_ref}, %{state | global_subscriptions: global_subs}}
    end

    def handle_call({:unsubscribe, _subscription_ref}, _from, state) do
      {:reply, :ok, state}
    end

    def handle_call({:request, %Proto.AccountDataRequest{subscribe: false}, _opts}, _from, state) do
      {:reply, {:ok, []}, state}
    end

    def handle_call({:request, %Proto.AccountDataRequest{} = _req, _opts}, _from, state) do
      if state.request_error do
        {:reply, {:error, state.request_error}, state}
      else
        {:reply, {:ok, state.initial_data}, state}
      end
    end

    def handle_call({:send_streaming_update, msg}, _from, state) do
      case Map.get(state.global_subscriptions, Proto.AccountDataRequest) do
        %{subscriber: subscriber, subscription_ref: ref} ->
          send(subscriber, {:ib_ex, ref, msg})
          {:reply, :ok, state}

        nil ->
          {:reply, {:error, :no_subscription}, state}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp start_pubsub do
    name = :"pubsub_#{System.unique_integer([:positive])}"
    {:ok, _} = Phoenix.PubSub.Supervisor.start_link(name: name)
    name
  end

  defp start_manager(client, pubsub, opts \\ []) do
    account = Keyword.get(opts, :account, "DU123456")

    AccountStateManager.start_link(
      client: client,
      account: account,
      pubsub: pubsub
    )
  end

  defp build_account_value(key, value, currency \\ "USD") do
    %Proto.AccountValue{
      key: key,
      value: value,
      currency: currency,
      account_name: "DU123456"
    }
  end

  defp build_portfolio_value(con_id, symbol, position, market_price, market_value) do
    %Proto.PortfolioValue{
      contract: %Proto.Contract{con_id: con_id, symbol: symbol, sec_type: "STK", currency: "USD", exchange: "SMART"},
      position: position,
      market_price: market_price,
      market_value: market_value,
      average_cost: 150.0,
      unrealized_pnl: 500.0,
      realized_pnl: 0.0,
      account_name: "DU123456"
    }
  end

  defp build_account_time(timestamp) do
    %Proto.AccountUpdateTime{time_stamp: timestamp}
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "start_link/1" do
    test "starts with empty state" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link()
      {:ok, manager} = start_manager(client, pubsub)

      assert AccountStateManager.account_values(manager) == %{}
      assert AccountStateManager.portfolio(manager) == %{}
    end

    test "requires client, account, and pubsub options" do
      pubsub = start_pubsub()
      Process.flag(:trap_exit, true)

      assert {:error, {%KeyError{key: :client}, _}} =
               AccountStateManager.start_link(account: "DU123456", pubsub: pubsub)

      {:ok, client} = MockClient.start_link()

      assert {:error, {%KeyError{key: :account}, _}} =
               AccountStateManager.start_link(client: client, pubsub: pubsub)

      assert {:error, {%KeyError{key: :pubsub}, _}} =
               AccountStateManager.start_link(client: client, account: "DU123456")

      Process.flag(:trap_exit, false)
    end

    test "accepts an optional name" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link()
      name = :"test_account_manager_#{System.unique_integer([:positive])}"

      {:ok, _manager} =
        AccountStateManager.start_link(client: client, account: "DU123456", pubsub: pubsub, name: name)

      assert Process.whereis(name) != nil
    end
  end

  describe "subscribe/2" do
    test "fetches initial account data and populates state" do
      pubsub = start_pubsub()

      initial_data = [
        build_account_value("NetLiquidation", "1000000.00"),
        build_account_value("BuyingPower", "500000.00"),
        build_portfolio_value(265_598, "AAPL", "100", 175.50, 17550.0),
        build_account_time("20:30")
      ]

      {:ok, client} = MockClient.start_link(initial_data: initial_data)
      {:ok, manager} = start_manager(client, pubsub)

      assert :ok = AccountStateManager.subscribe(manager, "my-account")

      # Verify account values were populated
      values = AccountStateManager.account_values(manager)
      assert values["NetLiquidation"] == %{value: "1000000.00", currency: "USD"}
      assert values["BuyingPower"] == %{value: "500000.00", currency: "USD"}

      # Verify portfolio was populated
      portfolio = AccountStateManager.portfolio(manager)
      assert Map.has_key?(portfolio, 265_598)
      assert portfolio[265_598].position == "100"
      assert portfolio[265_598].market_price == 175.50
      assert portfolio[265_598].market_value == 17550.0
      assert portfolio[265_598].contract.symbol == "AAPL"
    end

    test "returns error when request fails" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(request_error: :timeout)
      {:ok, manager} = start_manager(client, pubsub)

      assert {:error, :timeout} = AccountStateManager.subscribe(manager, "failing")

      # State should remain empty
      assert AccountStateManager.account_values(manager) == %{}
      assert AccountStateManager.portfolio(manager) == %{}
    end

    test "cancel-before-replace: re-subscribing with the same id replaces the old subscription" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [build_account_value("Key", "100.00")])
      {:ok, manager} = start_manager(client, pubsub)

      assert :ok = AccountStateManager.subscribe(manager, "reused")

      %{subscriptions: subs1} = :sys.get_state(manager)
      old_ref = subs1["reused"].client_ref

      assert :ok = AccountStateManager.subscribe(manager, "reused")

      %{subscriptions: subs2, refs: refs2} = :sys.get_state(manager)
      new_ref = subs2["reused"].client_ref

      assert new_ref != old_ref
      refute Map.has_key?(refs2, old_ref)
      assert refs2[new_ref] == "reused"
      assert map_size(refs2) == 1
    end

    test "handles empty initial data" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      assert :ok = AccountStateManager.subscribe(manager, "empty")

      assert AccountStateManager.account_values(manager) == %{}
      assert AccountStateManager.portfolio(manager) == %{}
    end

    test "returns {:error, :invalid_args} for non-string subscription_id" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link()
      {:ok, manager} = start_manager(client, pubsub)

      assert {:error, :invalid_args} = AccountStateManager.subscribe(manager, 123)
      assert {:error, :invalid_args} = AccountStateManager.subscribe(manager, :atom_id)
    end
  end

  describe "unsubscribe/2" do
    test "returns :ok for an active subscription" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      assert :ok = AccountStateManager.subscribe(manager, "unsub-ok")
      assert :ok = AccountStateManager.unsubscribe(manager, "unsub-ok")
    end

    test "returns {:error, :not_found} for unknown subscription_id" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link()
      {:ok, manager} = start_manager(client, pubsub)

      assert {:error, :not_found} = AccountStateManager.unsubscribe(manager, "nonexistent")
    end

    test "cleans up internal state after unsubscription" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      assert :ok = AccountStateManager.subscribe(manager, "cleanup")

      %{subscriptions: subs_before, refs: refs_before} = :sys.get_state(manager)
      assert Map.has_key?(subs_before, "cleanup")
      assert map_size(refs_before) == 1

      assert :ok = AccountStateManager.unsubscribe(manager, "cleanup")

      %{subscriptions: subs_after, refs: refs_after} = :sys.get_state(manager)
      refute Map.has_key?(subs_after, "cleanup")
      assert map_size(refs_after) == 0
    end

    test "returns {:error, :invalid_args} for non-string subscription_id" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link()
      {:ok, manager} = start_manager(client, pubsub)

      assert {:error, :invalid_args} = AccountStateManager.unsubscribe(manager, 123)
      assert {:error, :invalid_args} = AccountStateManager.unsubscribe(manager, :atom_id)
    end
  end

  describe "account_values/1" do
    test "returns the current account values snapshot" do
      pubsub = start_pubsub()

      initial_data = [
        build_account_value("NetLiquidation", "1000000.00"),
        build_account_value("TotalCashValue", "250000.00", "USD"),
        build_account_value("TotalCashValue", "150000.00", "EUR")
      ]

      {:ok, client} = MockClient.start_link(initial_data: initial_data)
      {:ok, manager} = start_manager(client, pubsub)
      :ok = AccountStateManager.subscribe(manager, "vals")

      values = AccountStateManager.account_values(manager)

      assert values["NetLiquidation"] == %{value: "1000000.00", currency: "USD"}
      # Last value for duplicate key wins (TWS sends per-currency values with same key)
      assert values["TotalCashValue"] == %{value: "150000.00", currency: "EUR"}
    end
  end

  describe "portfolio/1" do
    test "returns portfolio positions keyed by con_id" do
      pubsub = start_pubsub()

      initial_data = [
        build_portfolio_value(265_598, "AAPL", "100", 175.50, 17550.0),
        build_portfolio_value(756_733, "MSFT", "50", 380.00, 19000.0)
      ]

      {:ok, client} = MockClient.start_link(initial_data: initial_data)
      {:ok, manager} = start_manager(client, pubsub)
      :ok = AccountStateManager.subscribe(manager, "port")

      portfolio = AccountStateManager.portfolio(manager)

      assert map_size(portfolio) == 2
      assert portfolio[265_598].contract.symbol == "AAPL"
      assert portfolio[265_598].position == "100"
      assert portfolio[756_733].contract.symbol == "MSFT"
      assert portfolio[756_733].position == "50"
    end
  end

  describe "get_value/2" do
    test "returns {:ok, value} for existing keys" do
      pubsub = start_pubsub()
      initial_data = [build_account_value("NetLiquidation", "1000000.00")]

      {:ok, client} = MockClient.start_link(initial_data: initial_data)
      {:ok, manager} = start_manager(client, pubsub)
      :ok = AccountStateManager.subscribe(manager, "get-val")

      assert {:ok, %{value: "1000000.00", currency: "USD"}} =
               AccountStateManager.get_value(manager, "NetLiquidation")
    end

    test "returns {:error, :not_found} for missing keys" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)
      :ok = AccountStateManager.subscribe(manager, "get-val-missing")

      assert {:error, :not_found} = AccountStateManager.get_value(manager, "NonExistent")
    end
  end

  describe "PubSub account_value broadcast" do
    test "broadcasts {:account_value, ...} on incoming AccountValue streaming update" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "acct-val-event"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      # Simulate a streaming AccountValue update via the mock client
      msg = build_account_value("NetLiquidation", "1500000.00")
      MockClient.send_streaming_update(client, msg)

      assert_receive {:account_value, event}, 1_000
      assert event.key == "NetLiquidation"
      assert event.value == "1500000.00"
      assert event.currency == "USD"

      # Verify state was also updated
      assert {:ok, %{value: "1500000.00", currency: "USD"}} =
               AccountStateManager.get_value(manager, "NetLiquidation")
    end

    test "overwrites existing values with same key" do
      pubsub = start_pubsub()
      initial_data = [build_account_value("NetLiquidation", "1000000.00")]

      {:ok, client} = MockClient.start_link(initial_data: initial_data)
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "overwrite"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      # Verify initial value
      assert {:ok, %{value: "1000000.00"}} = AccountStateManager.get_value(manager, "NetLiquidation")

      # Simulate update
      MockClient.send_streaming_update(client, build_account_value("NetLiquidation", "1100000.00"))

      assert_receive {:account_value, %{key: "NetLiquidation", value: "1100000.00"}}, 1_000
      assert {:ok, %{value: "1100000.00"}} = AccountStateManager.get_value(manager, "NetLiquidation")
    end
  end

  describe "PubSub portfolio_update broadcast" do
    test "broadcasts {:portfolio_update, ...} on incoming PortfolioValue" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "port-event"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      msg = build_portfolio_value(265_598, "AAPL", "100", 175.50, 17550.0)
      MockClient.send_streaming_update(client, msg)

      assert_receive {:portfolio_update, event}, 1_000
      assert event.con_id == 265_598
      assert event.contract.symbol == "AAPL"
      assert event.position == "100"
      assert event.market_price == 175.50
      assert event.market_value == 17550.0
      assert event.average_cost == 150.0
      assert event.unrealized_pnl == 500.0
      assert event.realized_pnl == 0.0
      assert event.account_name == "DU123456"

      # Verify state was also updated
      portfolio = AccountStateManager.portfolio(manager)
      assert portfolio[265_598].contract.symbol == "AAPL"
      assert portfolio[265_598].position == "100"
    end

    test "updates existing position with new data" do
      pubsub = start_pubsub()
      initial_data = [build_portfolio_value(265_598, "AAPL", "100", 175.50, 17550.0)]

      {:ok, client} = MockClient.start_link(initial_data: initial_data)
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "port-update"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      # Simulate position update (price changed)
      MockClient.send_streaming_update(client, build_portfolio_value(265_598, "AAPL", "100", 180.00, 18000.0))

      assert_receive {:portfolio_update, event}, 1_000
      assert event.market_price == 180.00
      assert event.market_value == 18000.0

      portfolio = AccountStateManager.portfolio(manager)
      assert portfolio[265_598].market_price == 180.00
      assert portfolio[265_598].market_value == 18000.0
    end
  end

  describe "PubSub account_time broadcast" do
    test "broadcasts {:account_time, ...} on incoming AccountUpdateTime" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "time-event"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      MockClient.send_streaming_update(client, build_account_time("20:45"))

      assert_receive {:account_time, event}, 1_000
      assert event.timestamp == "20:45"

      state = :sys.get_state(manager)
      assert state.last_update_time == "20:45"
    end
  end

  describe "PubSub account_error broadcast" do
    test "broadcasts {:account_error, ...} on error" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "error-event"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      error = %IbEx.Client.Types.Error{id: 1, code: 321, message: "Account data error"}
      MockClient.send_streaming_update(client, {:error, error})

      assert_receive {:account_error, event}, 1_000
      assert event.code == 321
      assert event.message == "Account data error"
    end

    test "ignores errors for unknown refs" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:phantom")

      unknown_ref = make_ref()
      error = %IbEx.Client.Types.Error{id: 1, code: 321, message: "Should not arrive"}
      send(manager, {:ib_ex, unknown_ref, {:error, error}})

      refute_receive {:account_error, _}, 200
    end
  end

  describe "does not broadcast after unsubscription" do
    test "no events are broadcast after unsubscribing" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "unsub-no-broadcast"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      # Get the ref before unsubscribing
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      :ok = AccountStateManager.unsubscribe(manager, sub_id)

      # Send directly with the old ref -- should not broadcast
      send(manager, {:ib_ex, client_ref, build_account_value("NetLiquidation", "999.00")})

      refute_receive {:account_value, _}, 200
    end
  end

  describe "unrecognized messages" do
    test "ignores other {:ib_ex, ref, msg} types without crashing" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      :ok = AccountStateManager.subscribe(manager, "ignore")

      %{refs: refs} = :sys.get_state(manager)
      [{ref, _}] = Map.to_list(refs)

      send(manager, {:ib_ex, ref, %Proto.CurrentTime{current_time: 123}})
      Process.sleep(50)

      assert Process.alive?(manager)
    end

    test "ignores messages for unknown refs without crashing" do
      pubsub = start_pubsub()
      {:ok, client} = MockClient.start_link(initial_data: [])
      {:ok, manager} = start_manager(client, pubsub)

      unknown_ref = make_ref()
      send(manager, {:ib_ex, unknown_ref, build_account_value("Key", "123.00")})
      Process.sleep(50)

      assert Process.alive?(manager)
    end
  end

  describe "full lifecycle" do
    test "subscribe, receive initial data, then receive streaming updates" do
      pubsub = start_pubsub()

      initial_data = [
        build_account_value("NetLiquidation", "1000000.00"),
        build_portfolio_value(265_598, "AAPL", "100", 175.50, 17550.0),
        build_account_time("20:30")
      ]

      {:ok, client} = MockClient.start_link(initial_data: initial_data)
      {:ok, manager} = start_manager(client, pubsub)

      sub_id = "lifecycle"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:account:#{sub_id}")

      :ok = AccountStateManager.subscribe(manager, sub_id)

      # Verify initial state
      assert {:ok, %{value: "1000000.00"}} = AccountStateManager.get_value(manager, "NetLiquidation")
      assert map_size(AccountStateManager.portfolio(manager)) == 1

      # Simulate streaming updates
      MockClient.send_streaming_update(client, build_account_value("NetLiquidation", "1050000.00"))
      MockClient.send_streaming_update(client, build_portfolio_value(756_733, "MSFT", "50", 380.00, 19000.0))
      MockClient.send_streaming_update(client, build_account_time("20:35"))

      assert_receive {:account_value, %{key: "NetLiquidation", value: "1050000.00"}}, 1_000
      assert_receive {:portfolio_update, %{con_id: 756_733, contract: %{symbol: "MSFT"}}}, 1_000
      assert_receive {:account_time, %{timestamp: "20:35"}}, 1_000

      # Verify updated state
      assert {:ok, %{value: "1050000.00"}} = AccountStateManager.get_value(manager, "NetLiquidation")

      portfolio = AccountStateManager.portfolio(manager)
      assert map_size(portfolio) == 2
      assert portfolio[265_598].contract.symbol == "AAPL"
      assert portfolio[756_733].contract.symbol == "MSFT"

      state = :sys.get_state(manager)
      assert state.last_update_time == "20:35"
    end
  end
end
