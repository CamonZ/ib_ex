defmodule IbEx.Client.Messages.MarketData.TickPrice do
  @moduledoc """
  One of the subscription messages coming from subscribing to
  the market data request.

  Of note is that this type of message can trigger 2 calls
  in the receiving client.

  If the tick_type is related to one of the size tick types then
  it must also be trigger an event on tick size
  """

  defstruct request_id: nil,
            tick_type: nil,
            price: nil,
            size: nil,
            can_autoexecute?: nil,
            past_limit?: nil,
            pre_open?: nil,
            should_tick_for_size?: false

  @type t :: %__MODULE__{
          request_id: String.t(),
          tick_type: atom(),
          price: float() | nil,
          size: Decimal.t() | nil,
          can_autoexecute?: boolean() | nil,
          past_limit?: boolean() | nil,
          pre_open?: boolean() | nil,
          should_tick_for_size?: boolean()
        }

  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %MarketData.TickPrice{
        request_id: #{msg.request_id},
        tick_type: #{msg.tick_type},
        price: #{msg.price},
        size: #{msg.size},
        can_autoexecute?: #{msg.can_autoexecute?},
        past_limit?: #{msg.past_limit?},
        pre_open?: #{msg.pre_open?},
        should_tick_for_size?: #{msg.should_tick_for_size?}
      }
      """
    end
  end

  defimpl IbEx.Client.Protocols.Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
