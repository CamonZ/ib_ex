defmodule IbEx.Client.Orders do
  @moduledoc """
  Thematic module for order operations.

  Provides high-level functions for querying open orders, placing and cancelling
  orders, and retrieving completed orders. This module is stateless -- it builds
  proto request structs and delegates to `Client.request/3`, `Client.subscribe/3`,
  or `Client.command/2`.

  ## Functions

  * `open_orders/2` - Requests open orders for this client
    (bounded stream: accumulates OpenOrder responses, ends with OpenOrdersEnd, global correlation).
  * `all_open_orders/2` - Requests all open orders across all clients
    (bounded stream: accumulates OpenOrder responses, ends with OpenOrdersEnd, global correlation).
  * `completed_orders/2` - Requests completed orders
    (bounded stream: accumulates CompletedOrder responses, ends with CompletedOrdersEnd, global correlation).
  * `place/4` - Places an order for a contract
    (stream subscription with order_id correlation, receives OpenOrder, OrderStatus, etc.).
  * `cancel/3` - Cancels a specific order by order_id
    (fire-and-forget command).
  * `global_cancel/1` - Cancels all open orders
    (fire-and-forget command).
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract
  alias IbEx.Client.Types.Order, as: DomainOrder

  @doc """
  Requests open orders for this API client.

  Sends an `OpenOrdersRequest` through `Client.request/3` using global correlation.
  The response is a bounded stream that accumulates `OpenOrder` protos and ends
  with an `OpenOrdersEnd` marker.

  Returns `{:ok, [%Proto.OpenOrder{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, orders} = Orders.open_orders(client)

  """
  @spec open_orders(pid(), keyword()) :: {:ok, list()} | {:error, any()}
  def open_orders(client, opts \\ []) do
    request = %Proto.OpenOrdersRequest{}
    Client.request(client, request, opts)
  end

  @doc """
  Requests all open orders across all API clients.

  Sends an `AllOpenOrdersRequest` through `Client.request/3` using global correlation.
  The response is a bounded stream that accumulates `OpenOrder` protos and ends
  with an `OpenOrdersEnd` marker.

  Returns `{:ok, [%Proto.OpenOrder{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, orders} = Orders.all_open_orders(client)

  """
  @spec all_open_orders(pid(), keyword()) :: {:ok, list()} | {:error, any()}
  def all_open_orders(client, opts \\ []) do
    request = %Proto.AllOpenOrdersRequest{}
    Client.request(client, request, opts)
  end

  @doc """
  Requests completed orders.

  Sends a `CompletedOrdersRequest` through `Client.request/3` using global correlation.
  The response is a bounded stream that accumulates `CompletedOrder` protos and ends
  with a `CompletedOrdersEnd` marker.

  Returns `{:ok, [%Proto.CompletedOrder{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:api_only` - If `true`, only return orders placed through the API (default: `false`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, orders} = Orders.completed_orders(client)
      {:ok, orders} = Orders.completed_orders(client, api_only: true)

  """
  @spec completed_orders(pid(), keyword()) :: {:ok, list()} | {:error, any()}
  def completed_orders(client, opts \\ []) do
    request = %Proto.CompletedOrdersRequest{
      api_only: Keyword.get(opts, :api_only, false)
    }

    Client.request(client, request, opts)
  end

  @doc """
  Places an order for the given contract.

  Accepts domain contracts/orders or proto contracts/orders, builds a `PlaceOrderRequest`,
  and sends it through `Client.subscribe/3` using order_id correlation.

  The caller receives `{:ib_ex, subscription_ref, msg}` messages with OpenOrder,
  OrderStatus, OrderBound, CommissionAndFeesReport, and DeltaNeutralContract protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * Currently unused, reserved for future options.

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      order = %IbEx.Client.Types.Order{action: "BUY", total_quantity: 100, order_type: "LMT", limit_price: 150.0}
      {:ok, ref} = Orders.place(client, contract, order)

  """
  @spec place(pid(), struct(), struct(), keyword()) :: {:ok, reference()} | {:error, any()}
  def place(client, contract, order, opts \\ [])

  def place(client, %Proto.Contract{} = proto_contract, %Proto.Order{} = proto_order, opts) do
    request = %Proto.PlaceOrderRequest{
      contract: proto_contract,
      order: proto_order
    }

    Client.subscribe(client, request, opts)
  end

  def place(client, %DomainContract{} = contract, %Proto.Order{} = proto_order, opts) do
    place(client, Mapper.to_proto(contract), proto_order, opts)
  end

  def place(client, %Proto.Contract{} = proto_contract, %DomainOrder{} = order, opts) do
    place(client, proto_contract, Mapper.to_proto(order), opts)
  end

  def place(client, %DomainContract{} = contract, %DomainOrder{} = order, opts) do
    place(client, Mapper.to_proto(contract), Mapper.to_proto(order), opts)
  end

  @doc """
  Cancels a specific order by order_id.

  Builds a `CancelOrderRequest` and sends it as a fire-and-forget command
  through `Client.command/2`. Any resulting status updates (e.g. OrderStatus
  with "Cancelled") are delivered through the order's existing PlaceOrder
  lifecycle stream.

  Returns `:ok`.

  ## Options

  * `:manual_order_cancel_time` - Manual order cancel time string (default: `""`)
  * `:ext_operator` - External operator string (default: `""`)
  * `:manual_order_indicator` - Manual order indicator integer (default: `0`)

  ## Examples

      :ok = Orders.cancel(client, 42)
      :ok = Orders.cancel(client, 42, manual_order_cancel_time: "20240101 12:00:00")

  """
  @spec cancel(pid(), integer(), keyword()) :: :ok
  def cancel(client, order_id, opts \\ []) when is_integer(order_id) do
    order_cancel = %Proto.OrderCancel{
      manual_order_cancel_time: Keyword.get(opts, :manual_order_cancel_time, ""),
      ext_operator: Keyword.get(opts, :ext_operator, ""),
      manual_order_indicator: Keyword.get(opts, :manual_order_indicator, 0)
    }

    request = %Proto.CancelOrderRequest{
      order_id: order_id,
      order_cancel: order_cancel
    }

    Client.command(client, request)
  end

  @doc """
  Cancels all open orders globally.

  Sends a `GlobalCancelRequest` as a fire-and-forget command through
  `Client.command/2`. No response is expected from the server directly;
  cancellation status updates arrive through individual order lifecycle streams.

  Returns `:ok`.

  ## Examples

      :ok = Orders.global_cancel(client)

  """
  @spec global_cancel(pid()) :: :ok
  def global_cancel(client) do
    request = %Proto.GlobalCancelRequest{}
    Client.command(client, request)
  end
end
