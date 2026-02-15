defmodule IbEx.NewsManager do
  @moduledoc """
  GenServer that manages real-time tick-by-tick news headline subscriptions
  from TWS and broadcasts domain-friendly events via Phoenix.PubSub.

  Provides a simple API for subscribing to news headlines using shorthand
  contract tuples. Translates raw TWS `TickNews` proto messages into
  domain-friendly events and publishes them on per-subscription topics.

  Supports two subscription modes:

  1. **Per-symbol** -- subscribe to news headlines for a specific contract
     (e.g. `{:stock, "AAPL"}`). Uses ContractResolver to look up the full
     contract details.
  2. **Provider firehose** -- subscribe directly to a news provider's broad
     tape feed (e.g. `{:news, "BZ"}`).
     Builds broad tape contracts automatically (e.g. symbol `"BZ:BZ_ALL"`).

  ## Usage

      # Start dependencies
      {:ok, client} = IbEx.Client.start_link(...)
      {:ok, resolver} = IbEx.Client.ContractResolver.start_link(client: client)

      # Start the NewsManager
      {:ok, manager} = IbEx.NewsManager.start_link(
        client: client,
        resolver: resolver,
        pubsub: MyApp.PubSub
      )

      # Subscribe to the news topic BEFORE subscribing
      subscription_id = "aapl-news"
      Phoenix.PubSub.subscribe(MyApp.PubSub, "ib_ex:news:\#{subscription_id}")

      # Subscribe to news headlines for a specific stock
      :ok = IbEx.NewsManager.subscribe(manager, subscription_id, {:stock, "AAPL"})

      # Subscribe to a provider firehose
      :ok = IbEx.NewsManager.subscribe(manager, "bz-feed", {:news, "BZ"})

      # Receive events
      receive do
        {:news_headline, %{headline: headline}} -> IO.puts(headline)
        {:news_error, %{code: code, message: msg}} -> IO.puts("Error \#{code}: \#{msg}")
      end

  ## Event types

  Events are broadcast on the topic `"ib_ex:news:<subscription_id>"`:

  * `{:news_headline, %{provider_code: String.t(), article_id: String.t(), headline: String.t(), timestamp: DateTime.t(), extra_data: String.t()}}`
  * `{:news_error, %{code: integer, message: String.t()}}`
  """

  use GenServer

  alias IbEx.Client
  alias IbEx.Client.ContractResolver
  alias IbEx.Client.Proto.Protobuf, as: Proto

  # ---------------------------------------------------------------------------
  # Types
  # ---------------------------------------------------------------------------

  @type subscription_id :: String.t()
  @type contract_spec ::
          {:stock, symbol :: String.t()}
          | {:stock, symbol :: String.t(), currency :: String.t()}
          | {:forex, symbol :: String.t(), currency :: String.t()}
          | {:future, symbol :: String.t(), expiry :: String.t()}
          | {:option, symbol :: String.t(), expiry :: String.t(), strike :: number(), :call | :put}
          | {:news, provider_code :: String.t()}
  @type server :: GenServer.server()

  @type news_headline_event ::
          {:news_headline,
           %{
             provider_code: String.t(),
             article_id: String.t(),
             headline: String.t(),
             timestamp: DateTime.t(),
             extra_data: String.t()
           }}

  @type news_error_event :: {:news_error, %{code: integer(), message: String.t()}}
  @type news_event :: news_headline_event | news_error_event

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
  Starts the News Manager.

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
  Subscribes to real-time news headlines for the given contract.

  ## Arguments

  * `manager` -- pid or name of the NewsManager
  * `subscription_id` -- caller-provided string identifier for the subscription
  * `contract_spec` -- shorthand tuple (e.g. `{:stock, "AAPL"}`)
  * `opts` -- keyword list of options

  ## Options

  * `:generic_tick_list` -- override the generic tick list (default: `"mdoff"`,
    which requests news ticks only with no regular market data)
  * `:exchange` -- override the exchange from contract resolution
  * `:currency` -- override the currency from contract resolution

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec subscribe(server(), subscription_id, contract_spec, keyword()) :: :ok | {:error, term()}
  def subscribe(manager, subscription_id, contract_spec, opts \\ [])

  def subscribe(manager, subscription_id, contract_spec, opts)
      when is_binary(subscription_id) and is_tuple(contract_spec) do
    GenServer.call(manager, {:subscribe, subscription_id, contract_spec, opts})
  end

  def subscribe(_manager, _subscription_id, _contract_spec, _opts), do: {:error, :invalid_args}

  @doc """
  Cancels a news headline subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription
  does not exist.
  """
  @spec unsubscribe(server(), subscription_id) :: :ok | {:error, :not_found | :invalid_args}
  def unsubscribe(manager, subscription_id)

  def unsubscribe(manager, subscription_id) when is_binary(subscription_id),
    do: GenServer.call(manager, {:unsubscribe, subscription_id})

  def unsubscribe(_manager, _subscription_id), do: {:error, :invalid_args}

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
  def handle_call({:subscribe, subscription_id, contract_spec, opts}, _from, state) do
    state = cancel_existing_subscription(state, subscription_id)

    case resolve_and_subscribe(state, contract_spec, opts) do
      {:ok, client_ref} ->
        subscriptions = Map.put(state.subscriptions, subscription_id, %{client_ref: client_ref})
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

  @impl true
  def handle_info({:ib_ex, ref, %Proto.TickNews{} = tick_news}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event =
          {:news_headline,
           %{
             provider_code: tick_news.provider_code,
             article_id: tick_news.article_id,
             headline: tick_news.headline,
             timestamp: DateTime.from_unix!(tick_news.timestamp, :millisecond),
             extra_data: tick_news.extra_data
           }}

        broadcast(state.pubsub, sub_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, {:error, %IbEx.Client.Types.Error{} = error}}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = {:news_error, %{code: error.code, message: error.message}}
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

  defp resolve_and_subscribe(state, {:news, provider}, _opts) when is_binary(provider) do
    proto_contract = %Proto.Contract{
      symbol: "#{provider}:#{provider}_ALL",
      sec_type: "NEWS",
      exchange: provider
    }

    subscribe_to_market_data(state, proto_contract, [])
  end

  defp resolve_and_subscribe(state, contract_spec, opts) do
    with {:ok, details_list} <- ContractResolver.resolve(state.resolver, contract_spec),
         {:ok, proto_contract} <- ContractResolver.pick_contract(details_list, opts),
         {:ok, client_ref} <- subscribe_to_market_data(state, proto_contract, opts) do
      {:ok, client_ref}
    end
  end

  defp subscribe_to_market_data(state, proto_contract, opts) do
    request = build_market_data_request(proto_contract, opts)

    case Client.subscribe(state.client, request) do
      {:ok, client_ref} -> {:ok, client_ref}
      {:error, _reason} = error -> error
    end
  end

  defp build_market_data_request(proto_contract, opts) do
    %Proto.MarketDataRequest{
      contract: proto_contract,
      generic_tick_list: Keyword.get(opts, :generic_tick_list, "mdoff,292"),
      snapshot: false,
      regulatory_snapshot: false
    }
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

  defp broadcast(pubsub, subscription_id, event) do
    Phoenix.PubSub.broadcast(pubsub, "ib_ex:news:#{subscription_id}", event)
  end
end
