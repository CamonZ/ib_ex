defmodule IbEx.MarketDataManager do
  @moduledoc """
  GenServer that manages real-time market data subscriptions from TWS and
  broadcasts domain-friendly events via Phoenix.PubSub.

  Provides a simple API for subscribing to quotes, trades, and market depth
  using shorthand contract tuples. Translates raw TWS proto messages into
  domain-friendly events and publishes them on per-subscription topics.

  Supports three subscription types:

  1. **Quotes** (`:quotes`) -- Level I market data (TickPrice, TickSize, etc.)
     via `MarketData.subscribe/3`.
  2. **Trades** (`:trades`) -- tick-by-tick trade data (TickByTickData) via
     `MarketData.tick_by_tick_subscribe/3`.
  3. **Depth** (`:depth`) -- Level II order book (MarketDepth, MarketDepthL2)
     via `MarketDepth.subscribe/3`.

  ## Usage

      # Start dependencies
      {:ok, client} = IbEx.Client.start_link(...)
      {:ok, resolver} = IbEx.Client.ContractResolver.start_link(client: client)

      # Start the MarketDataManager
      {:ok, manager} = IbEx.MarketDataManager.start_link(
        client: client,
        resolver: resolver,
        pubsub: MyApp.PubSub
      )

      # Subscribe to the market data topic BEFORE subscribing
      subscription_id = "aapl-quotes"
      Phoenix.PubSub.subscribe(MyApp.PubSub, "ib_ex:market_data:\#{subscription_id}")

      # Subscribe to Level I quotes
      :ok = IbEx.MarketDataManager.subscribe(manager, subscription_id, :quotes, {:stock, "AAPL"})

      # Subscribe to tick-by-tick trades
      :ok = IbEx.MarketDataManager.subscribe(manager, "aapl-trades", :trades, {:stock, "AAPL"})

      # Subscribe to Level II depth
      :ok = IbEx.MarketDataManager.subscribe(manager, "aapl-depth", :depth, {:stock, "AAPL"})

      # List active subscriptions
      ["aapl-quotes", "aapl-trades", "aapl-depth"] = IbEx.MarketDataManager.subscriptions(manager)

  ## Event types

  Events are broadcast on the topic `"ib_ex:market_data:<subscription_id>"`:

  ### Quotes events
  * `{:tick_price, %{tick_type: atom, price: Decimal.t(), size: Decimal.t(), attr_mask: integer}}`
  * `{:tick_size, %{tick_type: atom, size: Decimal.t()}}`
  * `{:tick_string, %{tick_type: atom, value: String.t()}}`
  * `{:tick_generic, %{tick_type: atom, value: float}}`
  * `{:tick_option_computation, %{tick_type: atom, implied_vol: Decimal.t() | nil, delta: Decimal.t() | nil, ...}}`
  * `{:tick_req_params, %{min_tick: String.t(), bbo_exchange: String.t(), snapshot_permissions: integer}}`
  * `{:tick_snapshot_end, %{}}`

  ### Trades events
  * `{:trade, %{timestamp: DateTime.t(), price: Decimal.t(), size: Decimal.t(), exchange: String.t(), ...}}`
  * `{:bid_ask, %{timestamp: DateTime.t(), bid_price: Decimal.t(), ask_price: Decimal.t(), ...}}`
  * `{:mid_point, %{timestamp: DateTime.t(), price: Decimal.t()}}`

  ### Depth events
  * `{:depth_update, %{position: integer, operation: atom, side: atom, price: Decimal.t(), size: Decimal.t(), ...}}`

  ### Error events
  * `{:market_data_error, %{code: integer, message: String.t()}}`
  """

  use GenServer

  alias IbEx.Client
  alias IbEx.Client.Constants.TickTypes
  alias IbEx.Client.ContractResolver
  alias IbEx.Client.MarketData
  alias IbEx.Client.MarketDepth
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Utils

  # ---------------------------------------------------------------------------
  # Types
  # ---------------------------------------------------------------------------

  @type subscription_id :: String.t()
  @type subscription_type :: :quotes | :trades | :depth
  @type contract_spec ::
          {:stock, symbol :: String.t()}
          | {:stock, symbol :: String.t(), currency :: String.t()}
          | {:forex, symbol :: String.t(), currency :: String.t()}
          | {:future, symbol :: String.t(), expiry :: String.t()}
          | {:option, symbol :: String.t(), expiry :: String.t(), strike :: number(), :call | :put}
  @type server :: GenServer.server()

  @type market_data_error_event :: {:market_data_error, %{code: integer(), message: String.t()}}

  @valid_types [:quotes, :trades, :depth]

  # ---------------------------------------------------------------------------
  # Internal state
  # ---------------------------------------------------------------------------

  defstruct client: nil,
            resolver: nil,
            pubsub: nil,
            subscriptions: %{},
            refs: %{}

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Starts the Market Data Manager.

  ## Options

  * `:client` (required) -- pid of the `IbEx.Client` GenServer
  * `:resolver` (required) -- pid of a `IbEx.Client.ContractResolver` GenServer
  * `:pubsub` (required) -- Phoenix.PubSub server name
  * `:name` -- optional registered name for this GenServer
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Subscribes to real-time market data for the given contract.

  ## Arguments

  * `manager` -- pid or name of the MarketDataManager
  * `subscription_id` -- caller-provided string identifier for the subscription
  * `type` -- subscription type: `:quotes`, `:trades`, or `:depth`
  * `contract_spec` -- shorthand tuple (e.g. `{:stock, "AAPL"}`)
  * `opts` -- keyword list of options passed to the underlying subscribe call

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec subscribe(server(), subscription_id, subscription_type, contract_spec, keyword()) :: :ok | {:error, term()}
  def subscribe(manager, subscription_id, type, contract_spec, opts \\ [])

  def subscribe(manager, subscription_id, type, contract_spec, opts)
      when is_binary(subscription_id) and type in @valid_types and is_tuple(contract_spec) do
    GenServer.call(manager, {:subscribe, subscription_id, type, contract_spec, opts})
  end

  def subscribe(_manager, _subscription_id, _type, _contract_spec, _opts), do: {:error, :invalid_args}

  @doc """
  Cancels a market data subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription
  does not exist.
  """
  @spec unsubscribe(server(), subscription_id) :: :ok | {:error, :not_found | :invalid_args}
  def unsubscribe(manager, subscription_id)

  def unsubscribe(manager, subscription_id) when is_binary(subscription_id),
    do: GenServer.call(manager, {:unsubscribe, subscription_id})

  def unsubscribe(_manager, _subscription_id), do: {:error, :invalid_args}

  @doc """
  Returns a list of active subscription IDs.
  """
  @spec subscriptions(server()) :: [subscription_id]
  def subscriptions(manager) do
    GenServer.call(manager, :subscriptions)
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    resolver = Keyword.fetch!(opts, :resolver)
    pubsub = Keyword.fetch!(opts, :pubsub)

    {:ok, %__MODULE__{client: client, resolver: resolver, pubsub: pubsub}}
  end

  @impl true
  def handle_call({:subscribe, subscription_id, type, contract_spec, opts}, _from, state) do
    state = cancel_existing_subscription(state, subscription_id)

    case resolve_and_subscribe(state, type, contract_spec, opts) do
      {:ok, client_ref} ->
        subscriptions = Map.put(state.subscriptions, subscription_id, %{client_ref: client_ref, type: type})
        refs = Map.put(state.refs, client_ref, subscription_id)
        {:reply, :ok, %{state | subscriptions: subscriptions, refs: refs}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:unsubscribe, subscription_id}, _from, state) do
    case Map.get(state.subscriptions, subscription_id) do
      %{client_ref: client_ref} ->
        Client.unsubscribe(state.client, client_ref)
        subscriptions = Map.delete(state.subscriptions, subscription_id)
        refs = Map.delete(state.refs, client_ref)
        {:reply, :ok, %{state | subscriptions: subscriptions, refs: refs}}

      nil ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:subscriptions, _from, state) do
    {:reply, Map.keys(state.subscriptions), state}
  end

  @impl true
  def handle_info({:ib_ex, ref, {:error, %IbEx.Client.Types.Error{} = error}}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = {:market_data_error, %{code: error.code, message: error.message}}
        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickPrice{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event =
          {:tick_price,
           %{
             tick_type: resolve_tick_type(msg.tick_type),
             price: Utils.to_decimal(msg.price),
             size: Utils.to_decimal(msg.size),
             attr_mask: msg.attr_mask
           }}

        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickSize{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = {:tick_size, %{tick_type: resolve_tick_type(msg.tick_type), size: Utils.to_decimal(msg.size)}}
        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickString{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = {:tick_string, %{tick_type: resolve_tick_type(msg.tick_type), value: msg.value}}
        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickGeneric{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = {:tick_generic, %{tick_type: resolve_tick_type(msg.tick_type), value: msg.value}}
        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickOptionComputation{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event =
          {:tick_option_computation,
           %{
             tick_type: resolve_tick_type(msg.tick_type),
             tick_attrib: msg.tick_attrib,
             implied_vol: Utils.to_decimal(msg.implied_vol),
             delta: Utils.to_decimal(msg.delta),
             opt_price: Utils.to_decimal(msg.opt_price),
             pv_dividend: Utils.to_decimal(msg.pv_dividend),
             gamma: Utils.to_decimal(msg.gamma),
             vega: Utils.to_decimal(msg.vega),
             theta: Utils.to_decimal(msg.theta),
             und_price: Utils.to_decimal(msg.und_price)
           }}

        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickReqParams{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event =
          {:tick_req_params,
           %{min_tick: msg.min_tick, bbo_exchange: msg.bbo_exchange, snapshot_permissions: msg.snapshot_permissions}}

        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickSnapshotEnd{}}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        broadcast(state.pubsub, sub_id, {:tick_snapshot_end, %{}})
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.TickByTickData{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = translate_tick_by_tick(msg)
        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.MarketDepth{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = translate_depth_data(msg.market_depth_data)
        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.MarketDepthL2{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = translate_depth_data(msg.market_depth_data)
        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, _ref, _msg}, state) do
    {:noreply, state}
  end

  # ---------------------------------------------------------------------------
  # Internal helpers
  # ---------------------------------------------------------------------------

  defp resolve_and_subscribe(state, type, contract_spec, opts) do
    with {:ok, details_list} <- ContractResolver.resolve(state.resolver, contract_spec),
         {:ok, proto_contract} <- ContractResolver.pick_contract(details_list, opts),
         {:ok, client_ref} <- dispatch_subscribe(state.client, type, proto_contract, opts) do
      {:ok, client_ref}
    end
  end

  defp dispatch_subscribe(client, :quotes, proto_contract, opts) do
    MarketData.subscribe(client, proto_contract, opts)
  end

  defp dispatch_subscribe(client, :trades, proto_contract, opts) do
    MarketData.tick_by_tick_subscribe(client, proto_contract, opts)
  end

  defp dispatch_subscribe(client, :depth, proto_contract, opts) do
    MarketDepth.subscribe(client, proto_contract, opts)
  end

  defp cancel_existing_subscription(state, subscription_id) do
    case Map.get(state.subscriptions, subscription_id) do
      %{client_ref: client_ref} ->
        Client.unsubscribe(state.client, client_ref)

        %{
          state
          | subscriptions: Map.delete(state.subscriptions, subscription_id),
            refs: Map.delete(state.refs, client_ref)
        }

      nil ->
        state
    end
  end

  defp resolve_tick_type(tick_type) do
    case TickTypes.to_atom(tick_type) do
      {:ok, atom} -> atom
      {:error, :invalid_args} -> tick_type
    end
  end

  defp translate_tick_by_tick(%Proto.TickByTickData{tick: {:historical_tick_last, tick}}) do
    attrib = tick.tick_attrib_last

    {:trade,
     %{
       timestamp: DateTime.from_unix!(tick.time),
       price: Utils.to_decimal(tick.price),
       size: Utils.to_decimal(tick.size),
       exchange: tick.exchange || "",
       special_conditions: tick.special_conditions || "",
       past_limit: (attrib && attrib.past_limit) || false,
       unreported: (attrib && attrib.unreported) || false
     }}
  end

  defp translate_tick_by_tick(%Proto.TickByTickData{tick: {:historical_tick_bid_ask, tick}}) do
    attrib = tick.tick_attrib_bid_ask

    {:bid_ask,
     %{
       timestamp: DateTime.from_unix!(tick.time),
       bid_price: Utils.to_decimal(tick.price_bid),
       ask_price: Utils.to_decimal(tick.price_ask),
       bid_size: Utils.to_decimal(tick.size_bid),
       ask_size: Utils.to_decimal(tick.size_ask),
       bid_past_low: (attrib && attrib.bid_past_low) || false,
       ask_past_high: (attrib && attrib.ask_past_high) || false
     }}
  end

  defp translate_tick_by_tick(%Proto.TickByTickData{tick: {:historical_tick_mid_point, tick}}) do
    {:mid_point,
     %{
       timestamp: DateTime.from_unix!(tick.time),
       price: Utils.to_decimal(tick.price)
     }}
  end

  defp translate_depth_data(%Proto.MarketDepthData{} = data) do
    {:depth_update,
     %{
       position: data.position,
       operation: parse_depth_operation(data.operation),
       side: parse_depth_side(data.side),
       price: Utils.to_decimal(data.price),
       size: Utils.to_decimal(data.size),
       market_maker: data.market_maker || "",
       is_smart_depth: data.is_smart_depth || false
     }}
  end

  defp parse_depth_operation(0), do: :insert
  defp parse_depth_operation(1), do: :update
  defp parse_depth_operation(2), do: :delete

  defp parse_depth_side(0), do: :ask
  defp parse_depth_side(1), do: :bid

  defp broadcast(pubsub, subscription_id, event) do
    Phoenix.PubSub.broadcast(pubsub, "ib_ex:market_data:#{subscription_id}", event)
  end
end
