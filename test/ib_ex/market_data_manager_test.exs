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
      assert decoded.snapshot == false

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
