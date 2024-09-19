defmodule IbEx.Client.Messages.Orders.RequestCancelOrder do
  @moduledoc """
  Requests to cancel an Order

  The input parameters are:
  * order_id
  * %OrderCancel{}
  """
  alias IbEx.Client.Types.OrderCancel

  @version 1

  defstruct message_id: nil, version: @version, order_id: nil, request_id: nil, order_cancel_params: OrderCancel.new()

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          version: non_neg_integer(),
          order_id: non_neg_integer(),
          request_id: non_neg_integer(),
          order_cancel_params: OrderCancel.t()
        }

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Subscribable

  @spec new(non_neg_integer()) :: {:ok, t()} | {:error, :not_implemented}
  def new(order_id) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id, order_id: order_id, order_cancel_params: OrderCancel.new()}}

      :error ->
        {:error, :not_implemented}
    end
  end

  @spec new(non_neg_integer(), OrderCancel.t()) :: {:ok, t()} | {:error, :not_implemented}
  def new(order_id, %OrderCancel{} = order_cancel_params) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id, order_id: order_id, order_cancel_params: order_cancel_params}}

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      fields =
        [
          msg.message_id,
          msg.version,
          msg.order_id
        ] ++ OrderCancel.serialize(msg.order_cancel_params)

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> %MarketData.RequestCancelOrder{order_id: #{msg.order_id}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    # Subscription based on request_id, can handle multiple requests
    def subscribe(msg, pid, table_ref) do
      {:ok, request_id} = Subscriptions.reverse_lookup(table_ref, pid)
      :ets.delete(table_ref, request_id)

      {:ok, %{msg | request_id: request_id}}
    end

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
