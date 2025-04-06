defmodule IbEx.Client.Messages.MarketDepth.L2DataSingle do
  @moduledoc """
  Response to RequestData message with L2 orderbook data with a single entry per price level

  Receives a single update to the bids or the asks in the orderbook
  """

  alias IbEx.Client.Utils
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defstruct request_id: nil,
            position: nil,
            operation: nil,
            side: nil,
            price: nil,
            size: nil,
            timestamp: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          position: non_neg_integer(),
          operation: String.t(),
          side: String.t(),
          price: float(),
          size: non_neg_integer(),
          timestamp: DateTime.t()
        }

  def from_fields([_, req_id, pos, op_str, side_str, price, size]) do
    with {:ok, operation} <- Utils.MarketDepth.parse_operation(op_str),
         {:ok, side} <- Utils.MarketDepth.parse_side(side_str) do
      {
        :ok,
        %__MODULE__{
          request_id: req_id,
          position: Utils.to_integer(pos),
          operation: operation,
          side: side,
          price: Utils.to_float(price),
          size: Utils.to_integer(size),
          timestamp: DateTime.utc_now()
        }
      }
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %MarketDepth.L2DataSingle{
        request_id: #{msg.request_id},
        position: #{msg.position},
        operation: #{msg.operation},
        side: #{msg.side},
        price: #{msg.price},
        size: #{msg.size},
        timestamp: #{msg.timestamp}
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
