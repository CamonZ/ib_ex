defmodule IbEx.OrderManager do
  @moduledoc """
  GenServer that manages order placement, lifecycle tracking, and event broadcasting.

  Provides a simple API for placing orders using shorthand contract tuples and
  keyword options. Translates raw TWS proto messages into domain-friendly events
  and publishes them via Phoenix.PubSub on per-order topics.

  ## Usage

      # Start dependencies
      {:ok, client} = IbEx.Client.start_link(...)
      {:ok, resolver} = IbEx.Client.ContractResolver.start_link(client: client)

      # Start the OrderManager
      {:ok, manager} = IbEx.OrderManager.start_link(
        client: client,
        resolver: resolver,
        pubsub: MyApp.PubSub
      )

      # Subscribe to the order topic BEFORE placing
      order_id = "my-order-1"
      Phoenix.PubSub.subscribe(MyApp.PubSub, "ib_ex:orders:\#{order_id}")

      # Place an order (blocks until TWS confirms with perm_id)
      :ok = IbEx.OrderManager.place(manager, order_id, {:stock, "AAPL"}, :buy, 100, limit: 150.0)

      # Receive events
      receive do
        {:order_status, %{status: :submitted}} -> IO.puts("Submitted!")
        {:order_accepted, %{}} -> IO.puts("Accepted!")
        {:order_error, %{code: code, message: msg}} -> IO.puts("Error \#{code}: \#{msg}")
      end

  ## Event types

  Events are broadcast on the topic `"ib_ex:orders:<order_id>"`:

  * `{:order_status, %{status: atom, filled: Decimal.t(), remaining: Decimal.t(), avg_price: Decimal.t()}}`
  * `{:order_accepted, %{}}`
  * `{:order_error, %{code: integer, message: String.t()}}`
  """

  use GenServer

  alias IbEx.Client.Orders
  alias IbEx.Client.ContractResolver
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Utils

  # ---------------------------------------------------------------------------
  # Types
  # ---------------------------------------------------------------------------

  @type order_id :: String.t()
  @type action :: :buy | :sell
  @type contract_spec ::
          {:stock, symbol :: String.t()}
          | {:stock, symbol :: String.t(), currency :: String.t()}
          | {:forex, symbol :: String.t(), currency :: String.t()}
          | {:future, symbol :: String.t(), expiry :: String.t()}
          | {:option, symbol :: String.t(), expiry :: String.t(), strike :: number(), :call | :put}
  @type status :: :pre_submitted | :submitted | :filled | :cancelled | :inactive | :api_cancelled
  @type server :: GenServer.server()

  @type place_opt ::
          {:limit, number()}
          | {:stop, number()}
          | {:tif, atom() | String.t()}
          | {:outside_rth, boolean()}
          | {:transmit, boolean()}
          | {:exchange, String.t()}
          | {:currency, String.t()}

  @type order_status_event ::
          {:order_status, %{status: status, filled: Decimal.t(), remaining: Decimal.t(), avg_price: Decimal.t()}}
  @type order_accepted_event :: {:order_accepted, %{}}
  @type order_error_event :: {:order_error, %{code: integer(), message: String.t()}}
  @type order_event :: order_status_event | order_accepted_event | order_error_event

  @terminal_statuses [:filled, :cancelled, :api_cancelled, :inactive]

  @status_mapping %{
    "PreSubmitted" => :pre_submitted,
    "Submitted" => :submitted,
    "Filled" => :filled,
    "Cancelled" => :cancelled,
    "Inactive" => :inactive,
    "ApiCancelled" => :api_cancelled
  }

  # ---------------------------------------------------------------------------
  # Internal state
  # ---------------------------------------------------------------------------

  defstruct client: nil,
            resolver: nil,
            pubsub: nil,
            orders: %{},
            refs: %{},
            pending_placements: %{},
            seen_open_orders: MapSet.new()

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Starts the Order Manager.

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
  Places an order. Blocks until TWS confirms acceptance (non-zero perm_id).

  ## Arguments

  * `manager` -- pid or name of the OrderManager
  * `order_id` -- caller-provided string identifier for the order
  * `contract_spec` -- shorthand tuple (e.g. `{:stock, "AAPL"}`)
  * `action` -- `:buy` or `:sell`
  * `quantity` -- positive integer
  * `opts` -- keyword list of order options

  ## Order type inference

  * No price keyword -> MKT
  * `limit:` -> LMT
  * `stop:` -> STP
  * `stop:` + `limit:` -> STP LMT

  ## Other options

  * `:tif` -- time in force as atom (`:day`, `:gtc`, etc.). Default: `:day`
  * `:outside_rth` -- trade outside regular hours. Default: `false`
  * `:transmit` -- transmit order to exchange. Default: `true`
  * `:exchange` -- override the exchange from contract resolution
  * `:currency` -- override the currency from contract resolution

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec place(server(), order_id, contract_spec, action, pos_integer(), [place_opt]) :: :ok | {:error, term()}
  def place(manager, order_id, contract_spec, action, quantity, opts \\ [])

  def place(manager, order_id, contract_spec, action, quantity, opts)
      when is_binary(order_id) and is_tuple(contract_spec) and action in [:buy, :sell] and is_integer(quantity) and
             quantity > 0 do
    GenServer.call(manager, {:place, order_id, contract_spec, action, quantity, opts}, 30_000)
  end

  def place(_manager, _order_id, _contract_spec, _action, _quantity, _opts), do: {:error, :invalid_args}

  @doc """
  Cancels an order by its caller-provided order_id.

  Looks up the session_order_id from internal mapping and delegates to
  `IbEx.Client.Orders.cancel/3`.

  Returns `:ok` or `{:error, :not_found}`.
  """
  @spec cancel(server(), order_id, keyword()) :: :ok | {:error, :not_found | :invalid_args}
  def cancel(manager, order_id, opts \\ [])
  def cancel(manager, order_id, opts) when is_binary(order_id), do: GenServer.call(manager, {:cancel, order_id, opts})
  def cancel(_manager, _order_id, _opts), do: {:error, :invalid_args}

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
  def handle_call({:place, order_id, contract_spec, action, quantity, opts}, from, state) do
    case resolve_and_place(state, contract_spec, action, quantity, opts) do
      {:ok, ref} ->
        pending = %{from: from, order_id: order_id}
        pending_placements = Map.put(state.pending_placements, ref, pending)
        refs = Map.put(state.refs, ref, order_id)
        state = %{state | pending_placements: pending_placements, refs: refs}
        {:noreply, state}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:cancel, order_id, opts}, _from, state) do
    case Map.get(state.orders, order_id) do
      %{session_order_id: session_order_id} ->
        result = Orders.cancel(state.client, session_order_id, opts)
        {:reply, result, state}

      nil ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_info({:ib_ex, ref, %Proto.OrderBound{} = msg}, state) do
    state = maybe_confirm_placement(state, ref, msg.perm_id, msg.order_id)
    {:noreply, state}
  end

  def handle_info({:ib_ex, ref, %Proto.OrderStatus{} = msg}, state) do
    state = maybe_confirm_placement(state, ref, msg.perm_id, msg.order_id)

    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      caller_order_id ->
        status_atom = Map.fetch!(@status_mapping, msg.status)

        event =
          {:order_status,
           %{
             status: status_atom,
             filled: Utils.to_decimal(msg.filled),
             remaining: Utils.to_decimal(msg.remaining),
             avg_price: Utils.to_decimal(msg.avg_fill_price)
           }}

        broadcast(state.pubsub, caller_order_id, event)

        state =
          if status_atom in @terminal_statuses do
            %{
              state
              | orders: Map.delete(state.orders, caller_order_id),
                refs: Map.delete(state.refs, ref),
                seen_open_orders: MapSet.delete(state.seen_open_orders, caller_order_id)
            }
          else
            state
          end

        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, ref, %Proto.OpenOrder{}}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      caller_order_id ->
        if MapSet.member?(state.seen_open_orders, caller_order_id) do
          {:noreply, state}
        else
          broadcast(state.pubsub, caller_order_id, {:order_accepted, %{}})
          {:noreply, %{state | seen_open_orders: MapSet.put(state.seen_open_orders, caller_order_id)}}
        end
    end
  end

  def handle_info({:ib_ex, ref, {:error, %IbEx.Client.Types.Error{} = error}}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      caller_order_id ->
        event = {:order_error, %{code: error.code, message: error.message}}
        broadcast(state.pubsub, caller_order_id, event)
        {:noreply, state}
    end
  end

  def handle_info({:ib_ex, _ref, _msg}, state) do
    {:noreply, state}
  end

  # ---------------------------------------------------------------------------
  # Internal helpers
  # ---------------------------------------------------------------------------

  defp resolve_and_place(state, contract_spec, action, quantity, opts) do
    with {:ok, details_list} <- ContractResolver.resolve(state.resolver, contract_spec),
         {:ok, proto_contract} <- ContractResolver.pick_contract(details_list, opts) do
      proto_order = build_order(action, quantity, opts)
      Orders.place(state.client, proto_contract, proto_order, [])
    end
  end

  defp build_order(action, quantity, opts) do
    action_str =
      case action do
        :buy -> "BUY"
        :sell -> "SELL"
      end

    {order_type, lmt_price, aux_price} = infer_order_type(opts)

    tif = opts |> Keyword.get(:tif, :day) |> tif_to_string()
    outside_rth = Keyword.get(opts, :outside_rth, false)
    transmit = Keyword.get(opts, :transmit, true)

    %Proto.Order{
      action: action_str,
      total_quantity: Integer.to_string(quantity),
      order_type: order_type,
      lmt_price: lmt_price,
      aux_price: aux_price,
      tif: tif,
      outside_rth: outside_rth,
      transmit: transmit
    }
  end

  defp infer_order_type(opts) do
    limit = Keyword.get(opts, :limit)
    stop = Keyword.get(opts, :stop)

    case {stop, limit} do
      {nil, nil} -> {"MKT", nil, nil}
      {nil, lmt} -> {"LMT", lmt * 1.0, nil}
      {stp, nil} -> {"STP", nil, stp * 1.0}
      {stp, lmt} -> {"STP LMT", lmt * 1.0, stp * 1.0}
    end
  end

  defp tif_to_string(tif) when is_atom(tif), do: tif |> Atom.to_string() |> String.upcase()
  defp tif_to_string(tif) when is_binary(tif), do: tif

  defp maybe_confirm_placement(state, ref, perm_id, session_order_id) do
    case Map.get(state.pending_placements, ref) do
      %{from: from, order_id: caller_order_id} when is_integer(perm_id) and perm_id > 0 ->
        order_entry = %{perm_id: perm_id, session_order_id: session_order_id, ref: ref}
        orders = Map.put(state.orders, caller_order_id, order_entry)
        pending_placements = Map.delete(state.pending_placements, ref)
        GenServer.reply(from, :ok)
        %{state | orders: orders, pending_placements: pending_placements}

      _ ->
        state
    end
  end

  defp broadcast(pubsub, caller_order_id, event) do
    Phoenix.PubSub.broadcast(pubsub, "ib_ex:orders:#{caller_order_id}", event)
  end
end
