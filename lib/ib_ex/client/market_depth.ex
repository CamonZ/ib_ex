defmodule IbEx.Client.MarketDepth do
  @moduledoc """
  Thematic module for market depth (Level II) operations.

  Provides high-level functions for subscribing to real-time market depth streams
  and querying available market depth exchanges. This module is stateless -- it
  builds proto request structs and delegates to `Client.subscribe/3`,
  `Client.unsubscribe/2`, and `Client.request/3`.

  ## Functions

  * `subscribe/3` - Subscribes to a continuous market depth stream for a contract
    (MarketDepth, MarketDepthL2).
  * `unsubscribe/2` - Cancels a market depth subscription.
  * `exchanges/2` - Requests the list of exchanges providing market depth data.
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract

  @doc """
  Subscribes to a continuous market depth stream for the given contract.

  Builds a `MarketDepthRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with
  MarketDepth and MarketDepthL2 protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:num_rows` - Number of rows of market depth to return (default: `5`)
  * `:is_smart_depth` - Whether to use SMART depth aggregation (default: `false`)
  * `:market_depth_options` - Map of additional options (default: `%{}`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, ref} = MarketDepth.subscribe(client, contract)

  """
  @spec subscribe(pid(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def subscribe(client, contract, opts \\ [])

  def subscribe(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_market_depth_request(proto_contract, opts)
    Client.subscribe(client, request, opts)
  end

  def subscribe(client, %DomainContract{} = contract, opts) do
    subscribe(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Cancels a market depth subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelMarketDepth` message
  and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = MarketDepth.unsubscribe(client, subscription_ref)

  """
  @spec unsubscribe(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  @doc """
  Requests the list of exchanges providing market depth data.

  Sends a `MarketDepthExchangesRequest` through `Client.request/3` using global
  correlation (no req_id). Returns the list of depth market data descriptions.

  Returns `{:ok, %Proto.MarketDepthExchanges{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.MarketDepthExchanges{} = result} = MarketDepth.exchanges(client)
      result.depth_market_data_descriptions

  """
  @spec exchanges(pid(), keyword()) :: {:ok, struct()} | {:error, any()}
  def exchanges(client, opts \\ []) do
    request = %Proto.MarketDepthExchangesRequest{}
    Client.request(client, request, opts)
  end

  defp build_market_depth_request(proto_contract, opts) do
    %Proto.MarketDepthRequest{
      contract: proto_contract,
      num_rows: Keyword.get(opts, :num_rows, 5),
      is_smart_depth: Keyword.get(opts, :is_smart_depth),
      market_depth_options: Keyword.get(opts, :market_depth_options, %{})
    }
  end
end
