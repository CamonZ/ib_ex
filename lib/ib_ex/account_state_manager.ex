defmodule IbEx.AccountStateManager do
  @moduledoc """
  GenServer that subscribes to live account values and portfolio updates
  from TWS, maintaining a current snapshot of account state and broadcasting
  changes via Phoenix.PubSub.

  ## Usage

      {:ok, manager} = IbEx.AccountStateManager.start_link(
        client: client_pid,
        account: "DU123456",
        pubsub: MyApp.PubSub
      )

      # Subscribe to the PubSub topic BEFORE subscribing
      subscription_id = "my-account"
      Phoenix.PubSub.subscribe(MyApp.PubSub, "ib_ex:account:\#{subscription_id}")

      # Subscribe to TWS account updates
      :ok = IbEx.AccountStateManager.subscribe(manager, subscription_id)

      # Receive events
      receive do
        {:account_value, %{key: key, value: v, currency: c}} -> IO.puts("\#{key}: \#{v} \#{c}")
        {:portfolio_update, %{con_id: id, position: pos}} -> IO.puts("Position \#{id}: \#{pos}")
        {:account_time, %{timestamp: ts}} -> IO.puts("Updated: \#{ts}")
        {:account_error, %{code: code, message: msg}} -> IO.puts("Error \#{code}: \#{msg}")
      end

      # Query current state
      values = IbEx.AccountStateManager.account_values(manager)
      portfolio = IbEx.AccountStateManager.portfolio(manager)
      {:ok, nlv} = IbEx.AccountStateManager.get_value(manager, "NetLiquidation")

  ## Event types

  Events are broadcast on the topic `"ib_ex:account:<subscription_id>"`:

  * `{:account_value, %{key: String.t(), value: String.t(), currency: String.t()}}`
  * `{:portfolio_update, %{con_id: integer(), contract: Proto.Contract.t(), position: String.t(), market_price: float(), market_value: float(), average_cost: float(), unrealized_pnl: float(), realized_pnl: float(), account_name: String.t()}}`
  * `{:account_time, %{timestamp: String.t()}}`
  * `{:account_error, %{code: integer(), message: String.t()}}`

  ## State

  Maintains three pieces of account state:

    * **Account values** -- a map of `%{key => %{value: v, currency: c}}`
      keyed by the TWS account value key string (e.g. "NetLiquidation")
    * **Portfolio positions** -- a map of positions keyed by contract `con_id`
    * **Last update timestamp** -- the most recent account update time from TWS
  """

  use GenServer

  alias IbEx.Client
  alias IbEx.Client.Account
  alias IbEx.Client.Proto.Protobuf, as: Proto

  # ---------------------------------------------------------------------------
  # Types
  # ---------------------------------------------------------------------------

  @type subscription_id :: String.t()
  @type server :: GenServer.server()

  @type account_value_event :: {:account_value, %{key: String.t(), value: String.t(), currency: String.t()}}
  @type portfolio_update_event ::
          {:portfolio_update,
           %{
             con_id: integer(),
             contract: Proto.Contract.t(),
             position: String.t(),
             market_price: float(),
             market_value: float(),
             average_cost: float(),
             unrealized_pnl: float(),
             realized_pnl: float(),
             account_name: String.t()
           }}
  @type account_time_event :: {:account_time, %{timestamp: String.t()}}
  @type account_error_event :: {:account_error, %{code: integer(), message: String.t()}}
  @type account_event :: account_value_event | portfolio_update_event | account_time_event | account_error_event

  # ---------------------------------------------------------------------------
  # Internal state
  # ---------------------------------------------------------------------------

  defstruct client: nil,
            account: nil,
            pubsub: nil,
            subscriptions: %{},
            refs: %{},
            account_values: %{},
            portfolio: %{},
            last_update_time: nil

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Starts the Account State Manager.

  ## Options

    * `:client` (required) -- pid of the `IbEx.Client` GenServer
    * `:account` (required) -- TWS account code string (e.g. "DU123456")
    * `:pubsub` (required) -- Phoenix.PubSub server name
    * `:name` -- optional GenServer name registration
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Subscribes to account updates from TWS.

  Fetches the initial account snapshot and registers for ongoing streaming
  updates. Events are broadcast on `"ib_ex:account:<subscription_id>"`.

  If a subscription with the same `subscription_id` already exists, the old
  one is cancelled before creating the new one.

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec subscribe(server(), subscription_id()) :: :ok | {:error, term()}
  def subscribe(manager, subscription_id) when is_binary(subscription_id) do
    GenServer.call(manager, {:subscribe, subscription_id}, 15_000)
  end

  def subscribe(_manager, _subscription_id), do: {:error, :invalid_args}

  @doc """
  Cancels an account data subscription.

  Sends an unsubscribe request to TWS and removes the subscription.
  Returns `:ok` on success, or `{:error, :not_found}` if the subscription
  does not exist.
  """
  @spec unsubscribe(server(), subscription_id()) :: :ok | {:error, :not_found | :invalid_args}
  def unsubscribe(manager, subscription_id) when is_binary(subscription_id) do
    GenServer.call(manager, {:unsubscribe, subscription_id})
  end

  def unsubscribe(_manager, _subscription_id), do: {:error, :invalid_args}

  @doc """
  Returns the current account values snapshot.

  Returns a map of `%{key => %{value: value, currency: currency}}`.
  """
  @spec account_values(server()) :: map()
  def account_values(manager) do
    GenServer.call(manager, :account_values)
  end

  @doc """
  Returns the current portfolio positions.

  Returns a map of positions keyed by contract `con_id`.
  """
  @spec portfolio(server()) :: map()
  def portfolio(manager) do
    GenServer.call(manager, :portfolio)
  end

  @doc """
  Returns a specific account value by key.

  Returns `{:ok, %{value: value, currency: currency}}` if found,
  or `{:error, :not_found}` if the key does not exist.

  ## Examples

      {:ok, %{value: "1234567.89", currency: "USD"}} =
        AccountStateManager.get_value(manager, "NetLiquidation")

  """
  @spec get_value(server(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_value(manager, key) when is_binary(key) do
    GenServer.call(manager, {:get_value, key})
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    account = Keyword.fetch!(opts, :account)
    pubsub = Keyword.fetch!(opts, :pubsub)

    {:ok, %__MODULE__{client: client, account: account, pubsub: pubsub}}
  end

  @impl true
  def handle_call({:subscribe, subscription_id}, _from, state) do
    state = cancel_existing_subscription(state, subscription_id)

    case subscribe_to_account_data(state) do
      {:ok, client_ref, initial_data} ->
        subscriptions = Map.put(state.subscriptions, subscription_id, %{client_ref: client_ref})
        refs = Map.put(state.refs, client_ref, subscription_id)
        new_state = %{state | subscriptions: subscriptions, refs: refs}
        new_state = process_initial_data(initial_data, new_state)
        {:reply, :ok, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:unsubscribe, subscription_id}, _from, state) do
    case Map.get(state.subscriptions, subscription_id) do
      %{client_ref: client_ref} ->
        cancel_tws_subscription(state)
        Client.unsubscribe(state.client, client_ref)
        subscriptions = Map.delete(state.subscriptions, subscription_id)
        refs = Map.delete(state.refs, client_ref)
        {:reply, :ok, %{state | subscriptions: subscriptions, refs: refs}}

      nil ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:account_values, _from, state) do
    {:reply, state.account_values, state}
  end

  def handle_call(:portfolio, _from, state) do
    {:reply, state.portfolio, state}
  end

  def handle_call({:get_value, key}, _from, state) do
    case Map.fetch(state.account_values, key) do
      {:ok, value} -> {:reply, {:ok, value}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_info({:ib_ex, ref, %Proto.AccountValue{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        new_state = apply_account_value(msg, state)

        event =
          {:account_value, %{key: msg.key, value: msg.value, currency: msg.currency}}

        broadcast(state.pubsub, sub_id, event)
        {:noreply, new_state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.PortfolioValue{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        new_state = apply_portfolio_value(msg, state)

        event =
          {:portfolio_update,
           %{
             con_id: msg.contract.con_id,
             contract: msg.contract,
             position: msg.position,
             market_price: msg.market_price,
             market_value: msg.market_value,
             average_cost: msg.average_cost,
             unrealized_pnl: msg.unrealized_pnl,
             realized_pnl: msg.realized_pnl,
             account_name: msg.account_name
           }}

        broadcast(state.pubsub, sub_id, event)
        {:noreply, new_state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.AccountUpdateTime{} = msg}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        new_state = %{state | last_update_time: msg.time_stamp}
        event = {:account_time, %{timestamp: msg.time_stamp}}
        broadcast(state.pubsub, sub_id, event)
        {:noreply, new_state}
    end
  end

  def handle_info({:ib_ex, ref, {:error, %IbEx.Client.Types.Error{} = error}}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      sub_id ->
        event = {:account_error, %{code: error.code, message: error.message}}
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

  defp subscribe_to_account_data(state) do
    # First, request the initial account data snapshot. Client.request registers
    # a {:global, AccountDataRequest} request entry, accumulates AccountValue,
    # PortfolioValue, AccountUpdateTime responses until AccountDataEnd, then
    # removes the entry and returns the accumulated data.
    case Account.request_updates(state.client, state.account, subscribe: true, timeout: 10_000) do
      {:ok, initial_data} ->
        # Now register a global stream subscription for ongoing updates.
        # After the bounded request completed, the {:global, AccountDataRequest}
        # key was freed, so subscribe_global can claim it for streaming.
        case Client.subscribe_global(state.client, Proto.AccountDataRequest) do
          {:ok, client_ref} ->
            {:ok, client_ref, initial_data}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp cancel_existing_subscription(state, subscription_id) do
    case Map.get(state.subscriptions, subscription_id) do
      %{client_ref: client_ref} ->
        cancel_tws_subscription(state)
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

  defp cancel_tws_subscription(state) do
    # Tell TWS to stop sending account updates by sending subscribe: false
    Account.request_updates(state.client, state.account, subscribe: false, timeout: 5_000)
  catch
    :exit, _ -> :ok
  end

  defp process_initial_data(data, state) do
    Enum.reduce(data, state, fn msg, acc ->
      case msg do
        %Proto.AccountValue{} -> apply_account_value(msg, acc)
        %Proto.PortfolioValue{} -> apply_portfolio_value(msg, acc)
        %Proto.AccountUpdateTime{} -> %{acc | last_update_time: msg.time_stamp}
        _ -> acc
      end
    end)
  end

  defp apply_account_value(%Proto.AccountValue{key: key, value: value, currency: currency}, state) do
    entry = %{value: value, currency: currency}
    %{state | account_values: Map.put(state.account_values, key, entry)}
  end

  defp apply_portfolio_value(%Proto.PortfolioValue{contract: contract} = msg, state) do
    con_id = contract.con_id

    entry = %{
      contract: contract,
      position: msg.position,
      market_price: msg.market_price,
      market_value: msg.market_value,
      average_cost: msg.average_cost,
      unrealized_pnl: msg.unrealized_pnl,
      realized_pnl: msg.realized_pnl,
      account_name: msg.account_name
    }

    %{state | portfolio: Map.put(state.portfolio, con_id, entry)}
  end

  defp broadcast(pubsub, subscription_id, event) do
    Phoenix.PubSub.broadcast(pubsub, "ib_ex:account:#{subscription_id}", event)
  end
end
