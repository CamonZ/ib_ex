defmodule IbEx.Client.ContractResolver do
  @moduledoc """
  Ergonomic contract resolution with shorthand tuples and ETS caching.

  Translates shorthand tuples into fully resolved IB contracts by sending
  `ContractDataRequest` messages through `IbEx.Client.request/3` and caching
  results so repeated lookups don't hit TWS.

  Results are returned as `Types.ContractDetails` structs with parsed
  trading hours, liquid hours, and valid exchanges.

  ## Shorthand formats

      {:stock, "AAPL"}                              # USD, SMART exchange
      {:stock, "AAPL", "EUR"}                       # explicit currency
      {:forex, "EUR", "USD"}                         # forex pair
      {:future, "ES", "202506"}                      # future with expiry YYYYMM
      {:option, "AAPL", "20260320", 200.0, :call}   # option with expiry, strike, right
      {:option, "AAPL", "20260320", 200.0, :put}    # option put

  ## Usage

      {:ok, resolver} = ContractResolver.start_link(client: client_pid)
      {:ok, contracts} = ContractResolver.resolve(resolver, {:stock, "AAPL"})
      :ok = ContractResolver.clear_cache(resolver)

  """

  use GenServer

  alias IbEx.Client
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Proto.Mapper.Contract, as: ContractMapper
  alias IbEx.Client.Types.ContractDetails
  alias IbEx.Client.Proto.Mapper

  @default_timeout 10_000

  # -- Public API --

  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Resolves a shorthand tuple into a list of `ContractDetails` structs.

  Returns `{:ok, [%ContractDetails{}, ...]}` on success. When TWS returns
  multiple matches (e.g. same symbol on different exchanges), all are returned.

  Options:
    * `:timeout` - request timeout in milliseconds (default #{@default_timeout})
  """
  @spec resolve(GenServer.server(), tuple(), keyword()) :: {:ok, list(ContractDetails.t())} | {:error, term()}
  def resolve(server, shorthand, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    GenServer.call(server, {:resolve, shorthand, opts}, timeout + 5_000)
  end

  @doc """
  Clears the entire resolution cache.
  """
  @spec clear_cache(GenServer.server()) :: :ok
  def clear_cache(server) do
    GenServer.call(server, :clear_cache)
  end

  @doc """
  Picks the first contract from a list of resolved `ContractDetails` and
  converts it to a proto contract, applying optional overrides.

  ## Options

  * `:exchange` -- override the exchange
  * `:currency` -- override the currency
  """
  @spec pick_contract([ContractDetails.t()], keyword()) :: {:ok, Proto.Contract.t()} | {:error, :no_contracts_resolved}
  def pick_contract([], _opts), do: {:error, :no_contracts_resolved}

  def pick_contract([details | _rest], opts) do
    proto_contract = Mapper.to_proto(details.contract)

    proto_contract =
      if exchange = Keyword.get(opts, :exchange) do
        %{proto_contract | exchange: exchange}
      else
        proto_contract
      end

    proto_contract =
      if currency = Keyword.get(opts, :currency) do
        %{proto_contract | currency: currency}
      else
        proto_contract
      end

    {:ok, proto_contract}
  end

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    table = :ets.new(:contract_resolver_cache, [:set, :protected])
    {:ok, %{client: client, cache: table}}
  end

  @impl true
  def handle_call({:resolve, shorthand, opts}, _from, state) do
    case :ets.lookup(state.cache, shorthand) do
      [{^shorthand, cached}] ->
        {:reply, {:ok, cached}, state}

      [] ->
        case build_contract(shorthand) do
          {:ok, contract} ->
            request = %Proto.ContractDataRequest{contract: contract}
            timeout = Keyword.get(opts, :timeout, @default_timeout)

            case Client.request(state.client, request, timeout: timeout) do
              {:ok, results} ->
                mapped = Enum.map(results, &to_contract_details/1)
                :ets.insert(state.cache, {shorthand, mapped})
                {:reply, {:ok, mapped}, state}

              {:error, _reason} = error ->
                {:reply, error, state}
            end

          {:error, _reason} = error ->
            {:reply, error, state}
        end
    end
  end

  def handle_call(:clear_cache, _from, state) do
    :ets.delete_all_objects(state.cache)
    {:reply, :ok, state}
  end

  # -- Private helpers --

  defp build_contract(shorthand) do
    case shorthand do
      {:stock, symbol} when is_binary(symbol) ->
        {:ok, %Proto.Contract{symbol: symbol, sec_type: "STK", currency: "USD", exchange: "SMART"}}

      {:stock, symbol, currency} when is_binary(symbol) and is_binary(currency) ->
        {:ok, %Proto.Contract{symbol: symbol, sec_type: "STK", currency: currency, exchange: "SMART"}}

      {:forex, symbol, currency} when is_binary(symbol) and is_binary(currency) ->
        {:ok, %Proto.Contract{symbol: symbol, sec_type: "CASH", currency: currency, exchange: "IDEALPRO"}}

      {:future, symbol, expiry} when is_binary(symbol) and is_binary(expiry) ->
        {:ok,
         %Proto.Contract{
           symbol: symbol,
           sec_type: "FUT",
           currency: "USD",
           exchange: "CME",
           last_trade_date_or_contract_month: expiry
         }}

      {:option, symbol, expiry, strike, right}
      when is_binary(symbol) and is_binary(expiry) and is_number(strike) and right in [:call, :put] ->
        right_str = if right == :call, do: "C", else: "P"

        {:ok,
         %Proto.Contract{
           symbol: symbol,
           sec_type: "OPT",
           currency: "USD",
           exchange: "SMART",
           last_trade_date_or_contract_month: expiry,
           strike: strike / 1,
           right: right_str
         }}

      _other ->
        {:error, :invalid_shorthand}
    end
  end

  defp to_contract_details(%Proto.ContractData{} = data) do
    contract = if data.contract, do: ContractMapper.from_proto(data.contract), else: nil

    details_attrs =
      if data.contract_details do
        data.contract_details
        |> Map.from_struct()
        |> Map.put(:contract, contract)
        |> Map.put(:under_conid, data.contract_details.under_con_id)
        |> Map.delete(:under_con_id)
      else
        %{contract: contract}
      end

    ContractDetails.new(details_attrs)
  end
end
