defmodule IbEx.Client.Messages.Orders.Status do
  defstruct host_order_id: nil,
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
