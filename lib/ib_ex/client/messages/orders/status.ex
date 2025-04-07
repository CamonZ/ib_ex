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

  alias IbEx.Client.Protocols.Traceable

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

    {:ok, msg}
  end

  def from_fields(_fields) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- OrderStatus{
        host_order_id: #{msg.host_order_id},
        api_client_order_id: #{msg.api_client_order_id},
        parent_id: #{msg.parent_id},
        status: #{msg.status},
        filled: #{msg.filled},
        remaining: #{msg.remaining},
        average_fill_price: #{msg.average_fill_price},
        last_fill_price: #{msg.last_fill_price},
        why_held: #{msg.why_held},
        market_cap_price: #{msg.market_cap_price}
      }
      """
    end
  end
end
