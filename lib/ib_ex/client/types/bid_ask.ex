defmodule IbEx.Client.Types.BidAsk do
  @moduledoc """
    Represents a Bid/Ask pair with its price and size from the Time & Sales feed
  """

  defstruct timestamp: nil,
            bid_price: nil,
            bid_size: nil,
            ask_price: nil,
            ask_size: nil,
            mask: nil,
            bid_past_low: nil,
            ask_past_high: nil

  alias IbEx.Client.Utils

  def from_tick_by_tick([ts, bid_price_str, ask_price_str, bid_size_str, ask_size_str, mask_str]) do
    case DateTime.from_unix(String.to_integer(ts)) do
      {:ok, timestamp} ->
        {
          :ok,
          %__MODULE__{
            timestamp: timestamp,
            bid_price: Decimal.new(bid_price_str),
            bid_size: String.to_integer(bid_size_str),
            ask_price: Decimal.new(ask_price_str),
            ask_size: String.to_integer(ask_size_str),
            mask: String.to_integer(mask_str),
            bid_past_low: Utils.boolify_mask(mask_str, 1),
            ask_past_high: Utils.boolify_mask(mask_str, 2)
          }
        }

      _ ->
        {:error, :invalid_args}
    end
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def from_tick_by_tick(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(tick, _opts) do
      "BidAsk{
        timestamp: #{tick.timestamp},
        bid_price: #{tick.bid_price},
        bid_size: #{tick.bid_size},
        ask_price: #{tick.ask_price},
        ask_size: #{tick.ask_size}
      }"
    end
  end
end
