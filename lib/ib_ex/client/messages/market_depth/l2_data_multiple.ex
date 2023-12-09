defmodule IbEx.Client.Messages.MarketDepth.L2DataMultiple do
  @moduledoc """
  Response to RequestData message with L2 orderbook data with multiple market makers

  Receives a single update to the bids or the asks in the orderbook
  """

  defstruct request_id: nil,
            position: nil,
            market_maker: nil,
            operation: nil,
            side: nil,
            price: nil,
            size: nil,
            smart_depth?: nil,
            timestamp: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          position: non_neg_integer(),
          market_maker: String.t(),
          operation: String.t(),
          side: String.t(),
          price: float(),
          size: non_neg_integer(),
          smart_depth?: boolean(),
          timestamp: DateTime.t()
        }

  alias IbEx.Client.Utils

  def from_fields([_, req_id, pos, market_maker, op_str, side_str, price, size, smart_depth]) do
    with {:ok, operation} <- Utils.MarketDepth.parse_operation(op_str),
         {:ok, side} <- Utils.MarketDepth.parse_side(side_str) do
      {
        :ok,
        %__MODULE__{
          request_id: req_id,
          position: Utils.to_integer(pos),
          market_maker: market_maker,
          operation: operation,
          side: side,
          price: Utils.to_float(price),
          size: Utils.to_integer(size),
          smart_depth?: Utils.to_bool(smart_depth),
          timestamp: DateTime.utc_now()
        }
      }
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %MarketDepth.L2DataMultiple{
        request_id: #{msg.request_id},
        position: #{msg.position},
        market_maker: #{msg.market_maker},
        operation: #{msg.operation},
        side: #{msg.side},
        price: #{msg.price},
        size: #{msg.size},
        smart_depth?: #{msg.smart_depth?},
        timestamp: #{msg.timestamp}
      """
    end
  end
end
