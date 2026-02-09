defmodule IbEx.Client.MarketData do
  @moduledoc """
  Thematic module for market data operations.

  Provides high-level functions for subscribing to real-time market data streams
  and tick-by-tick data. This module is stateless -- it builds proto request
  structs and delegates to `Client.subscribe/3` and `Client.unsubscribe/2`.

  ## Functions

  * `subscribe/3` - Subscribes to a continuous market data stream for a contract
    (TickPrice, TickSize, TickString, TickGeneric, TickOptionComputation).
  * `snapshot/3` - Requests a market data snapshot (same stream, ends with TickSnapshotEnd).
  * `unsubscribe/2` - Cancels a market data or tick-by-tick subscription.
  * `tick_by_tick_subscribe/3` - Subscribes to tick-by-tick data for a contract.
  * `tick_by_tick_unsubscribe/2` - Cancels a tick-by-tick subscription.
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract

  @doc """
  Subscribes to a continuous market data stream for the given contract.

  Builds a `MarketDataRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with
  TickPrice, TickSize, TickString, TickGeneric, and TickOptionComputation protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:generic_tick_list` - Comma-separated string of generic tick types (default: `""`)
  * `:regulatory_snapshot` - Whether to request a regulatory snapshot (default: `false`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, ref} = MarketData.subscribe(client, contract)

  """
  @spec subscribe(pid(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def subscribe(client, contract, opts \\ [])

  def subscribe(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_market_data_request(proto_contract, opts)
    Client.subscribe(client, request, opts)
  end

  def subscribe(client, %DomainContract{} = contract, opts) do
    subscribe(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Requests a market data snapshot for the given contract.

  Same as `subscribe/3` but sets the snapshot flag to `true` on the request.
  The stream ends with a `TickSnapshotEnd` message, after which no more ticks arrive.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:generic_tick_list` - Comma-separated string of generic tick types (default: `""`)
  * `:regulatory_snapshot` - Whether to request a regulatory snapshot (default: `false`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, ref} = MarketData.snapshot(client, contract)

  """
  @spec snapshot(pid(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def snapshot(client, contract, opts \\ [])

  def snapshot(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_market_data_request(proto_contract, Keyword.put(opts, :snapshot, true))
    Client.subscribe(client, request, opts)
  end

  def snapshot(client, %DomainContract{} = contract, opts) do
    snapshot(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Cancels a market data or tick-by-tick subscription.

  Delegates to `Client.unsubscribe/2` which sends the appropriate cancel
  message (CancelMarketData or CancelTickByTick) and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = MarketData.unsubscribe(client, subscription_ref)

  """
  @spec unsubscribe(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  @doc """
  Subscribes to tick-by-tick data for the given contract.

  Builds a `TickByTickRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with
  `TickByTickData` protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:tick_type` - The tick type string: `"Last"`, `"AllLast"`, `"BidAsk"`, or `"MidPoint"` (default: `"Last"`)
  * `:number_of_ticks` - Number of ticks to return (default: `0`, meaning all)
  * `:ignore_size` - Whether to ignore size in tick data (default: `false`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, ref} = MarketData.tick_by_tick_subscribe(client, contract, tick_type: "BidAsk")

  """
  @spec tick_by_tick_subscribe(pid(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def tick_by_tick_subscribe(client, contract, opts \\ [])

  def tick_by_tick_subscribe(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_tick_by_tick_request(proto_contract, opts)
    Client.subscribe(client, request, opts)
  end

  def tick_by_tick_subscribe(client, %DomainContract{} = contract, opts) do
    tick_by_tick_subscribe(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Cancels a tick-by-tick subscription.

  Alias for `unsubscribe/2` -- both market data and tick-by-tick subscriptions
  are cancelled through the same `Client.unsubscribe/2` mechanism.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = MarketData.tick_by_tick_unsubscribe(client, subscription_ref)

  """
  @spec tick_by_tick_unsubscribe(pid(), reference()) :: :ok | {:error, :not_found}
  def tick_by_tick_unsubscribe(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  defp build_market_data_request(proto_contract, opts) do
    %Proto.MarketDataRequest{
      contract: proto_contract,
      generic_tick_list: Keyword.get(opts, :generic_tick_list, ""),
      snapshot: Keyword.get(opts, :snapshot, false),
      regulatory_snapshot: Keyword.get(opts, :regulatory_snapshot, false)
    }
  end

  defp build_tick_by_tick_request(proto_contract, opts) do
    %Proto.TickByTickRequest{
      contract: proto_contract,
      tick_type: Keyword.get(opts, :tick_type, "Last"),
      number_of_ticks: Keyword.get(opts, :number_of_ticks, 0),
      ignore_size: Keyword.get(opts, :ignore_size, false)
    }
  end
end
