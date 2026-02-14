defmodule IbEx.NewsManagerTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.ContractResolver
  alias IbEx.NewsManager
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
      case :ets.lookup(:news_manager_test_pids, state.client) do
        [{_, test_pid}] -> send(test_pid, {:tws_sent, msg})
        [] -> :ok
      end

      {:reply, :ok, state}
    end
  end

  # ---------------------------------------------------------------------------
  # Wire encoding helpers
  # ---------------------------------------------------------------------------

  @tick_news_wire_id 284
  @contract_data_wire_id 210
  @contract_data_end_wire_id 252

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_recording_client do
    {:ok, client} = Client.start_link(connection_handler: RecordingConnection)
    :ets.insert(:news_manager_test_pids, {client, self()})
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
    {:ok, manager} = NewsManager.start_link(client: client, resolver: resolver, pubsub: pubsub)
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
  defp subscribe_with_resolve(manager, client, subscription_id, contract_spec, opts \\ []) do
    task =
      Task.async(fn ->
        NewsManager.subscribe(manager, subscription_id, contract_spec, opts)
      end)

    Process.sleep(50)

    # Handle the resolver contract data request
    req_id = extract_req_id_from_tws_message()
    inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

    # Consume the MarketDataRequest TWS message
    assert_receive {:tws_sent, _mkt_data_msg}, 1_000

    Task.await(task, 5_000)
  end

  # ---------------------------------------------------------------------------
  # Setup
  # ---------------------------------------------------------------------------

  setup_all do
    :ets.new(:news_manager_test_pids, [:named_table, :public, :set])
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
    test "starts the News Manager with required options", %{client: client, resolver: resolver, pubsub: pubsub} do
      {:ok, manager} = NewsManager.start_link(client: client, resolver: resolver, pubsub: pubsub)
      assert Process.alive?(manager)
    end

    test "accepts an optional name", %{client: client, resolver: resolver, pubsub: pubsub} do
      name = :"test_news_manager_#{System.unique_integer([:positive])}"
      {:ok, _manager} = NewsManager.start_link(client: client, resolver: resolver, pubsub: pubsub, name: name)
      assert Process.whereis(name) != nil
    end

    test "fails to start when :client option is missing", %{resolver: resolver, pubsub: pubsub} do
      Process.flag(:trap_exit, true)
      assert {:error, {%KeyError{key: :client}, _}} = NewsManager.start_link(resolver: resolver, pubsub: pubsub)
    end

    test "fails to start when :resolver option is missing", %{client: client, pubsub: pubsub} do
      Process.flag(:trap_exit, true)
      assert {:error, {%KeyError{key: :resolver}, _}} = NewsManager.start_link(client: client, pubsub: pubsub)
    end

    test "fails to start when :pubsub option is missing", %{client: client, resolver: resolver} do
      Process.flag(:trap_exit, true)
      assert {:error, {%KeyError{key: :pubsub}, _}} = NewsManager.start_link(client: client, resolver: resolver)
    end
  end

  # ---------------------------------------------------------------------------
  # subscribe/4
  # ---------------------------------------------------------------------------

  describe "subscribe/4" do
    test "returns :ok on successful subscription", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "aapl-news", {:stock, "AAPL"})
    end

    test "tracks subscription in internal state", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "tracked-sub", {:stock, "AAPL"})

      %{subscriptions: subscriptions, refs: refs} = :sys.get_state(manager)
      assert Map.has_key?(subscriptions, "tracked-sub")
      assert map_size(refs) == 1
    end

    test "cancels previous subscription when reusing subscription_id", %{pubsub: pubsub} do
      {:ok, client} = Client.start_link(connection_handler: MockConnection)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      assert :ok = NewsManager.subscribe(manager, "reused", {:news, "BZ"})

      %{subscriptions: subs1} = :sys.get_state(manager)
      old_ref = subs1["reused"].client_ref

      assert :ok = NewsManager.subscribe(manager, "reused", {:news, "FLY"})

      %{subscriptions: subs2, refs: refs2} = :sys.get_state(manager)
      new_ref = subs2["reused"].client_ref

      assert new_ref != old_ref
      refute Map.has_key?(refs2, old_ref)
      assert refs2[new_ref] == "reused"
      assert map_size(refs2) == 1
    end

    test "sends MarketDataRequest with mdoff,292 generic_tick_list to TWS", %{pubsub: pubsub} do
      client = start_recording_client()
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      task =
        Task.async(fn ->
          NewsManager.subscribe(manager, "wire-check", {:stock, "AAPL"})
        end)

      Process.sleep(50)
      req_id = extract_req_id_from_tws_message()
      inject_contract_data(client, req_id, [aapl_contract_data(req_id)])

      assert_receive {:tws_sent, mkt_data_msg}, 1_000
      <<_wire_id::big-integer-size(32), payload::binary>> = mkt_data_msg
      decoded = Protobuf.decode(payload, Proto.MarketDataRequest)

      assert decoded.generic_tick_list == "mdoff,292"
      assert decoded.snapshot == false
      assert decoded.regulatory_snapshot == false
      assert decoded.contract.symbol == "AAPL"
      assert decoded.contract.sec_type == "STK"

      assert :ok = Task.await(task, 5_000)
    end

    test "returns {:error, :invalid_args} for non-string subscription_id", %{manager: manager} do
      assert {:error, :invalid_args} = NewsManager.subscribe(manager, 123, {:stock, "AAPL"})
      assert {:error, :invalid_args} = NewsManager.subscribe(manager, :atom_id, {:stock, "AAPL"})
    end

    test "returns {:error, :invalid_args} for non-tuple contract_spec", %{manager: manager} do
      assert {:error, :invalid_args} = NewsManager.subscribe(manager, "sub-1", "AAPL")
      assert {:error, :invalid_args} = NewsManager.subscribe(manager, "sub-1", 42)
    end
  end

  # ---------------------------------------------------------------------------
  # unsubscribe/2
  # ---------------------------------------------------------------------------

  describe "unsubscribe/2" do
    test "returns :ok for an active subscription", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "unsub-ok", {:stock, "AAPL"})
      assert :ok = NewsManager.unsubscribe(manager, "unsub-ok")
    end

    test "returns {:error, :not_found} for unknown subscription_id", %{manager: manager} do
      assert {:error, :not_found} = NewsManager.unsubscribe(manager, "nonexistent")
    end

    test "cleans up internal state after unsubscription", %{manager: manager, client: client} do
      assert :ok = subscribe_with_resolve(manager, client, "cleanup-sub", {:stock, "AAPL"})

      %{subscriptions: subs_before, refs: refs_before} = :sys.get_state(manager)
      assert Map.has_key?(subs_before, "cleanup-sub")
      assert map_size(refs_before) == 1

      assert :ok = NewsManager.unsubscribe(manager, "cleanup-sub")

      %{subscriptions: subs_after, refs: refs_after} = :sys.get_state(manager)
      refute Map.has_key?(subs_after, "cleanup-sub")
      assert map_size(refs_after) == 0
    end

    test "returns {:error, :invalid_args} for non-string subscription_id", %{manager: manager} do
      assert {:error, :invalid_args} = NewsManager.unsubscribe(manager, 123)
      assert {:error, :invalid_args} = NewsManager.unsubscribe(manager, :atom_id)
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- news_headline broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub news_headline broadcast" do
    test "broadcasts {:news_headline, ...} with domain fields on TickNews", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "headline-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, {:stock, "AAPL"})

      # Get the client_ref from internal state to inject the TickNews
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      tick_news = %Proto.TickNews{
        req_id: 1,
        timestamp: 1_705_312_200_000,
        provider_code: "BRFG",
        article_id: "BRFG$12345678",
        headline: "AAPL: Apple reports record earnings",
        extra_data: "K:0"
      }

      send(manager, {:ib_ex, client_ref, tick_news})

      assert_receive {:news_headline, event}, 1_000
      assert event.provider_code == "BRFG"
      assert event.article_id == "BRFG$12345678"
      assert event.headline == "AAPL: Apple reports record earnings"
      assert event.timestamp == DateTime.from_unix!(1_705_312_200_000, :millisecond)
      assert event.extra_data == "K:0"
    end

    test "delivers headlines from multiple subscriptions to correct topics", %{pubsub: pubsub} do
      client = start_recording_client()
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:aapl-multi")
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:msft-multi")

      assert :ok = subscribe_with_resolve(manager, client, "aapl-multi", {:stock, "AAPL"})

      # Second subscription uses a different contract spec to avoid resolver cache hit
      assert :ok = subscribe_with_resolve(manager, client, "msft-multi", {:stock, "AAPL", "USD"})

      %{subscriptions: subs} = :sys.get_state(manager)
      aapl_ref = subs["aapl-multi"].client_ref
      msft_ref = subs["msft-multi"].client_ref

      send(
        manager,
        {:ib_ex, aapl_ref,
         %Proto.TickNews{
           req_id: 1,
           timestamp: 1_705_312_200_000,
           provider_code: "BRFG",
           article_id: "BRFG$11111111",
           headline: "AAPL: New product launch",
           extra_data: ""
         }}
      )

      send(
        manager,
        {:ib_ex, msft_ref,
         %Proto.TickNews{
           req_id: 2,
           timestamp: 1_705_312_300_000,
           provider_code: "DJ-N",
           article_id: "DJ-N$22222222",
           headline: "MSFT: Cloud revenue surges",
           extra_data: ""
         }}
      )

      assert_receive {:news_headline, aapl_event}, 1_000
      assert aapl_event.headline == "AAPL: New product launch"
      assert aapl_event.provider_code == "BRFG"

      assert_receive {:news_headline, msft_event}, 1_000
      assert msft_event.headline == "MSFT: Cloud revenue surges"
      assert msft_event.provider_code == "DJ-N"
    end

    test "handles multiple headlines on the same subscription", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "multi-headline"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      send(
        manager,
        {:ib_ex, client_ref,
         %Proto.TickNews{
           req_id: 1,
           timestamp: 1_705_312_200_000,
           provider_code: "BRFG",
           article_id: "BRFG$00000001",
           headline: "First headline",
           extra_data: ""
         }}
      )

      send(
        manager,
        {:ib_ex, client_ref,
         %Proto.TickNews{
           req_id: 1,
           timestamp: 1_705_312_300_000,
           provider_code: "BRFG",
           article_id: "BRFG$00000002",
           headline: "Second headline",
           extra_data: ""
         }}
      )

      assert_receive {:news_headline, h1}, 1_000
      assert h1.headline == "First headline"
      assert h1.article_id == "BRFG$00000001"
      assert h1.timestamp == DateTime.from_unix!(1_705_312_200_000, :millisecond)

      assert_receive {:news_headline, h2}, 1_000
      assert h2.headline == "Second headline"
      assert h2.article_id == "BRFG$00000002"
      assert h2.timestamp == DateTime.from_unix!(1_705_312_300_000, :millisecond)
    end

    test "does not broadcast after unsubscription", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "unsub-no-broadcast"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      assert :ok = NewsManager.unsubscribe(manager, sub_id)

      send(
        manager,
        {:ib_ex, client_ref,
         %Proto.TickNews{
           req_id: 1,
           timestamp: 1_705_312_200_000,
           provider_code: "BRFG",
           article_id: "BRFG$99999999",
           headline: "Should not be delivered",
           extra_data: ""
         }}
      )

      refute_receive {:news_headline, _}, 200
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- news_headline via wire-encoded TickNews
  # ---------------------------------------------------------------------------

  describe "PubSub news_headline via wire-encoded TickNews" do
    test "broadcasts when TickNews arrives via Client.process_message", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "wire-headline"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, {:stock, "AAPL"})

      # Get the req_id that was assigned by the client for the market data stream
      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      # Look up the req_id associated with this subscription ref in the client's ETS table
      %{subscriptions_table_ref: table_ref} = :sys.get_state(client)

      {:request_id, req_id} =
        :ets.foldl(
          fn
            {key, %{type: :stream, subscription_ref: ^client_ref}}, _acc -> key
            _other, acc -> acc
          end,
          nil,
          table_ref
        )

      tick_news = %Proto.TickNews{
        req_id: req_id,
        timestamp: 1_705_312_200_000,
        provider_code: "BRFG",
        article_id: "BRFG$12345678",
        headline: "AAPL: Apple reports record earnings",
        extra_data: "K:0"
      }

      Client.process_message(client, wire_message(@tick_news_wire_id, tick_news))

      assert_receive {:news_headline, event}, 1_000
      assert event.provider_code == "BRFG"
      assert event.article_id == "BRFG$12345678"
      assert event.headline == "AAPL: Apple reports record earnings"
      assert event.timestamp == DateTime.from_unix!(1_705_312_200_000, :millisecond)
      assert event.extra_data == "K:0"
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub -- news_error broadcast
  # ---------------------------------------------------------------------------

  describe "PubSub news_error broadcast" do
    test "broadcasts {:news_error, %{code: ..., message: ...}} on Error", %{
      manager: manager,
      client: client,
      pubsub: pubsub
    } do
      sub_id = "error-1"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:#{sub_id}")

      assert :ok = subscribe_with_resolve(manager, client, sub_id, {:stock, "AAPL"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      error = %IbEx.Client.Types.Error{id: 1, code: 354, message: "Not subscribed to news"}
      send(manager, {:ib_ex, client_ref, {:error, error}})

      assert_receive {:news_error, %{code: 354, message: "Not subscribed to news"}}, 1_000
    end

    test "ignores errors for unknown refs", %{manager: manager, pubsub: pubsub} do
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:phantom")

      unknown_ref = make_ref()
      error = %IbEx.Client.Types.Error{id: 1, code: 354, message: "Not subscribed"}
      send(manager, {:ib_ex, unknown_ref, {:error, error}})

      refute_receive {:news_error, _}, 200
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
      assert :ok = subscribe_with_resolve(manager, client, "ignore-1", {:stock, "AAPL"})

      %{refs: refs} = :sys.get_state(manager)
      [{ref, _}] = Map.to_list(refs)

      # Send a TickPrice message (not explicitly handled)
      send(manager, {:ib_ex, ref, %Proto.TickPrice{req_id: 1, tick_type: 1, price: 150.0}})
      Process.sleep(50)

      assert Process.alive?(manager)
    end

    test "ignores messages for unknown refs without crashing", %{manager: manager} do
      unknown_ref = make_ref()

      send(
        manager,
        {:ib_ex, unknown_ref,
         %Proto.TickNews{
           req_id: 999,
           timestamp: 1_705_312_200_000,
           provider_code: "BRFG",
           article_id: "BRFG$00000000",
           headline: "Orphan headline",
           extra_data: ""
         }}
      )

      Process.sleep(50)
      assert Process.alive?(manager)
    end
  end

  # ---------------------------------------------------------------------------
  # subscribe/4 with news providers
  # ---------------------------------------------------------------------------

  describe "subscribe/4 with news providers" do
    test "subscribes to a single news provider", %{pubsub: pubsub} do
      {:ok, client} = Client.start_link(connection_handler: MockConnection)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      assert :ok = NewsManager.subscribe(manager, "bz", {:news, "BZ"})

      %{subscriptions: subs, refs: refs} = :sys.get_state(manager)
      assert %{client_ref: _ref} = subs["bz"]
      assert map_size(refs) == 1
    end

    test "builds correct NEWS contract", %{pubsub: pubsub} do
      client = start_recording_client()
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      assert :ok = NewsManager.subscribe(manager, "bz-wire", {:news, "BZ"})

      assert_receive {:tws_sent, mkt_data_msg}, 1_000
      <<_wire_id::big-integer-size(32), payload::binary>> = mkt_data_msg
      decoded = Protobuf.decode(payload, Proto.MarketDataRequest)

      assert decoded.contract.symbol == "BZ:BZ_ALL"
      assert decoded.contract.sec_type == "NEWS"
      assert decoded.contract.exchange == "BZ"
      assert decoded.generic_tick_list == "mdoff,292"
    end
  end

  # ---------------------------------------------------------------------------
  # PubSub news_headline from provider subscription
  # ---------------------------------------------------------------------------

  describe "PubSub news_headline from provider subscription" do
    test "broadcasts headlines from provider subscription", %{pubsub: pubsub} do
      {:ok, client} = Client.start_link(connection_handler: MockConnection)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      sub_id = "bz-headlines"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:#{sub_id}")

      assert :ok = NewsManager.subscribe(manager, sub_id, {:news, "BZ"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      tick_news = %Proto.TickNews{
        req_id: 1,
        timestamp: 1_705_312_200_000,
        provider_code: "BZ",
        article_id: "BZ$12345678",
        headline: "Breaking: Major market move",
        extra_data: ""
      }

      send(manager, {:ib_ex, client_ref, tick_news})

      assert_receive {:news_headline, event}, 1_000
      assert event.provider_code == "BZ"
      assert event.article_id == "BZ$12345678"
      assert event.headline == "Breaking: Major market move"
      assert event.timestamp == DateTime.from_unix!(1_705_312_200_000, :millisecond)
    end
  end

  # ---------------------------------------------------------------------------
  # unsubscribe/2 with provider subscriptions
  # ---------------------------------------------------------------------------

  describe "unsubscribe/2 with provider subscriptions" do
    test "unsubscribes provider ref", %{pubsub: pubsub} do
      {:ok, client} = Client.start_link(connection_handler: MockConnection)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      assert :ok = NewsManager.subscribe(manager, "unsub-provider", {:news, "BZ"})

      %{subscriptions: subs_before, refs: refs_before} = :sys.get_state(manager)
      assert Map.has_key?(subs_before, "unsub-provider")
      assert map_size(refs_before) == 1

      assert :ok = NewsManager.unsubscribe(manager, "unsub-provider")

      %{subscriptions: subs_after, refs: refs_after} = :sys.get_state(manager)
      refute Map.has_key?(subs_after, "unsub-provider")
      assert map_size(refs_after) == 0
    end

    test "does not broadcast after provider unsubscription", %{pubsub: pubsub} do
      {:ok, client} = Client.start_link(connection_handler: MockConnection)
      resolver = start_resolver(client)
      manager = start_manager(client, resolver, pubsub)

      sub_id = "unsub-no-broadcast-provider"
      Phoenix.PubSub.subscribe(pubsub, "ib_ex:news:#{sub_id}")

      assert :ok = NewsManager.subscribe(manager, sub_id, {:news, "BZ"})

      %{subscriptions: %{^sub_id => %{client_ref: client_ref}}} = :sys.get_state(manager)

      assert :ok = NewsManager.unsubscribe(manager, sub_id)

      send(
        manager,
        {:ib_ex, client_ref,
         %Proto.TickNews{
           req_id: 1,
           timestamp: 1_705_312_200_000,
           provider_code: "BZ",
           article_id: "BZ$99999999",
           headline: "Should not be delivered",
           extra_data: ""
         }}
      )

      refute_receive {:news_headline, _}, 200
    end
  end
end
