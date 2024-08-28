defmodule IbEx.Client.Messages.Orders.Status do
  defstruct version: nil,
            host_order_id: nil,
            api_client_order_id: nil,
            parent_id: nil,
            status: nil,
            filled: nil,
            remaining: nil,
            average_fill_price: nil,
            last_fill_price: nil,
            why_held: nil,
            market_cap_price: nil

  require Logger

  def from_fields(fields) when length(fields) == 11 do
    [
      api_client_order_id,
      status,
      filled,
      remaining,
      avg_fill_price,
      perm_id,
      parent_id,
      last_fill_price,
      _client_id,
      why_held,
      mkt_cap_price
    ] = fields

    msg = %__MODULE__{
      host_order_id: perm_id,
      api_client_order_id: api_client_order_id,
      parent_id: parent_id,
      status: String.downcase(status),
      filled: Decimal.new(filled),
      remaining: Decimal.new(remaining),
      average_fill_price: Decimal.new(avg_fill_price),
      last_fill_price: Decimal.new(last_fill_price),
      why_held: why_held,
      market_cap_price: Decimal.new(mkt_cap_price)
    }

    Logger.info("Parsed OrderStatus: #{inspect(fields)}")
    {:ok, msg}
  end

  def from_fields(fields) do
    Logger.warning("Trying to parse message as OrderStatus: #{inspect(fields)}")
    {:error, :invalid_args}
  end
end
