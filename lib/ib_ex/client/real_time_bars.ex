defmodule IbEx.Client.RealTimeBars do
  @moduledoc """
  Thematic module for real-time bar operations.

  Provides high-level functions for subscribing to and unsubscribing from
  real-time 5-second bar streams. This module is stateless -- it builds proto
  request structs and delegates to `Client.subscribe/3` and
  `Client.unsubscribe/2`.

  ## Functions

  * `subscribe/3` - Subscribes to a continuous real-time bars stream for a contract
    (RealTimeBarTick).
  * `unsubscribe/2` - Cancels a real-time bars subscription.
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract

  @doc """
  Subscribes to a continuous real-time bars stream for the given contract.

  Builds a `RealTimeBarsRequest` and sends it through `Client.subscribe/3`.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with
  RealTimeBarTick protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:bar_size` - Bar size in seconds (default: `5`, the only value IB supports)
  * `:what_to_show` - Data type to show (default: `"TRADES"`)
  * `:use_rth` - Whether to use regular trading hours only (default: `false`)
  * `:real_time_bars_options` - Map of additional options (default: `%{}`)

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, ref} = RealTimeBars.subscribe(client, contract)

  """
  @spec subscribe(pid(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def subscribe(client, contract, opts \\ [])

  def subscribe(client, %Proto.Contract{} = proto_contract, opts) do
    request = build_real_time_bars_request(proto_contract, opts)
    Client.subscribe(client, request, opts)
  end

  def subscribe(client, %DomainContract{} = contract, opts) do
    subscribe(client, Mapper.to_proto(contract), opts)
  end

  @doc """
  Cancels a real-time bars subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelRealTimeBars` message
  and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = RealTimeBars.unsubscribe(client, subscription_ref)

  """
  @spec unsubscribe(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end

  defp build_real_time_bars_request(proto_contract, opts) do
    %Proto.RealTimeBarsRequest{
      contract: proto_contract,
      bar_size: Keyword.get(opts, :bar_size, 5),
      what_to_show: Keyword.get(opts, :what_to_show, "TRADES"),
      use_rth: Keyword.get(opts, :use_rth, false),
      real_time_bars_options: Keyword.get(opts, :real_time_bars_options, %{})
    }
  end
end
