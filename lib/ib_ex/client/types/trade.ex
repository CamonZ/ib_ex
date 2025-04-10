defmodule IbEx.Client.Types.Trade do
  @moduledoc """
  Represents a trade from the public Time & Sales feed.
  """

  defstruct timestamp: nil,
            mask: nil,
            size: nil,
            price: nil,
            exchange: nil,
            conditions: nil,
            past_limit: nil,
            unreported: nil

  alias IbEx.Client.Utils
  alias IbEx.Client.Protocols.Traceable

  def from_tick_by_tick([ts, price_str, size_str, mask_str, exchange, conditions]) do
    from_historical_ticks_last([ts, mask_str, size_str, price_str, exchange, conditions])
  end

  def from_tick_by_tick(_) do
    {:error, :invalid_args}
  end

  def from_historical_ticks_last([ts, mask, size_str, price_str, exchange, conditions]) do
    case DateTime.from_unix(String.to_integer(ts)) do
      {:ok, timestamp} ->
        {
          :ok,
          %__MODULE__{
            timestamp: timestamp,
            price: Utils.to_float(price_str),
            size: Utils.to_integer(size_str),
            mask: Utils.to_integer(mask),
            conditions: conditions,
            exchange: exchange,
            past_limit: Utils.boolify_mask(mask, 1),
            unreported: Utils.boolify_mask(mask, 2)
          }
        }

      _ ->
        {:error, :invalid_args}
    end
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def from_historical_ticks_last(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(trade) do
      "%Trade{timestamp: #{trade.timestamp}, price: #{trade.price}, size: #{trade.size}, exchange: #{trade.exchange}, conditions: #{trade.conditions}}"
    end
  end
end
