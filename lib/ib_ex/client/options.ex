defmodule IbEx.Client.Options do
  @moduledoc """
  Thematic module for options operations.

  Provides high-level functions for calculating implied volatility, option
  prices, and querying security definition option parameters. This module
  is stateless -- it builds proto request structs and delegates to
  `Client.subscribe/3`, `Client.unsubscribe/2`, and `Client.request/3`.

  ## Functions

  * `implied_volatility/3` - Subscribes to implied volatility calculations
    (stream subscription with req_id correlation, receives TickOptionComputation protos).
  * `cancel_implied_volatility/2` - Cancels an implied volatility subscription.
  * `option_price/3` - Subscribes to option price calculations
    (stream subscription with req_id correlation, receives TickOptionComputation protos).
  * `cancel_option_price/2` - Cancels an option price subscription.
  * `sec_def_params/3` - Requests security definition option parameters
    (bounded stream: accumulates SecDefOptParameter responses, ends with SecDefOptParameterEnd).
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Protobuf, as: Proto

  @doc """
  Subscribes to implied volatility calculations for the given contract.

  Builds a `CalculateImpliedVolatilityRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with
  `TickOptionComputation` protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:implied_volatility_options` - Map of additional options (default: `%{}`)

  ## Examples

      contract = %Proto.Contract{symbol: "AAPL", sec_type: "OPT", currency: "USD"}
      {:ok, ref} = Options.implied_volatility(client, contract, 150.0, 155.0)

  """
  @spec implied_volatility(pid(), struct(), number(), number(), keyword()) ::
          {:ok, reference()} | {:error, any()}
  def implied_volatility(client, contract, option_price, under_price, opts \\ []) do
    request = %Proto.CalculateImpliedVolatilityRequest{
      contract: contract,
      option_price: option_price,
      under_price: under_price,
      implied_volatility_options: Keyword.get(opts, :implied_volatility_options, %{})
    }

    Client.subscribe(client, request, opts)
  end

  @doc """
  Cancels an implied volatility calculation subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelCalculateImpliedVolatility`
  message and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = Options.cancel_implied_volatility(client, subscription_ref)

  """
  @spec cancel_implied_volatility(pid(), reference()) :: :ok | {:error, :not_found}
  def cancel_implied_volatility(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  @doc """
  Subscribes to option price calculations for the given contract.

  Builds a `CalculateOptionPriceRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with
  `TickOptionComputation` protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:option_price_options` - Map of additional options (default: `%{}`)

  ## Examples

      contract = %Proto.Contract{symbol: "AAPL", sec_type: "OPT", currency: "USD"}
      {:ok, ref} = Options.option_price(client, contract, 0.25, 155.0)

  """
  @spec option_price(pid(), struct(), number(), number(), keyword()) ::
          {:ok, reference()} | {:error, any()}
  def option_price(client, contract, volatility, under_price, opts \\ []) do
    request = %Proto.CalculateOptionPriceRequest{
      contract: contract,
      volatility: volatility,
      under_price: under_price,
      option_price_options: Keyword.get(opts, :option_price_options, %{})
    }

    Client.subscribe(client, request, opts)
  end

  @doc """
  Cancels an option price calculation subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelCalculateOptionPrice`
  message and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = Options.cancel_option_price(client, subscription_ref)

  """
  @spec cancel_option_price(pid(), reference()) :: :ok | {:error, :not_found}
  def cancel_option_price(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  @doc """
  Requests security definition option parameters for the given underlying.

  Sends a `SecDefOptParamsRequest` through `Client.request/3` as a bounded stream.
  The response accumulates `SecDefOptParameter` protos and ends with a
  `SecDefOptParameterEnd` marker.

  Returns `{:ok, [%Proto.SecDefOptParameter{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:fut_fop_exchange` - Exchange for futures options (default: `""`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, params} = Options.sec_def_params(client, "AAPL", "STK", 265598)

  """
  @spec sec_def_params(pid(), String.t(), String.t(), integer(), keyword()) ::
          {:ok, list()} | {:error, any()}
  def sec_def_params(client, underlying_symbol, underlying_sec_type, underlying_con_id, opts \\ [])
      when is_integer(underlying_con_id) do
    request = %Proto.SecDefOptParamsRequest{
      underlying_symbol: underlying_symbol,
      fut_fop_exchange: Keyword.get(opts, :fut_fop_exchange, ""),
      underlying_sec_type: underlying_sec_type,
      underlying_con_id: underlying_con_id
    }

    Client.request(client, request, opts)
  end
end
