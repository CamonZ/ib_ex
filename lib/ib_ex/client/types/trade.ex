defmodule IbEx.Client.Types.Trade do
  defstruct timestamp: nil,
            mask: nil,
            size: nil,
            price: nil,
            exchange: nil,
            conditions: nil

  def new([ts, mask, size_str, price_str, exchange, conditions] = fields) do
    with {:ok, timestamp} <- DateTime.from_unix(String.to_integer(ts)),
         price <- Decimal.new(price_str),
         size <- Decimal.new(size_str) do
      trade = %__MODULE__{
        timestamp: timestamp,
        price: price,
        size: size,
        mask: mask,
        conditions: conditions,
        exchange: exchange
      }

      {:ok, trade}
    else
      _ ->
        {:error, {:parser_failure, fields}}
    end
  rescue
    _ ->
      {:error, {:parser_failure, fields}}
  end

  def new(fields) do
    {:error, {:parser_failure, fields}}
  end

  def to_string(%__MODULE__{} = trade) do
    "#{trade.timestamp} #{trade.price} #{trade.size} #{trade.exchange} #{trade.conditions}"
  end
end
