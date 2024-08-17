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

  alias IbEx.Client.Utils
  alias IbEx.Client.Constants.TickTypes

  @autoexecute_flag 1
  @past_limit_flag 2
  @pre_open_flag 4

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([_, request_id, tick_type_str, price, size, mask]) do
    tick_type = decode_tick_type(tick_type_str)

    msg = %__MODULE__{
      request_id: request_id,
      tick_type: tick_type,
      price: Utils.to_float(price),
      size: Utils.to_decimal(size),
      can_autoexecute?: Utils.boolify_mask(mask, @autoexecute_flag),
      past_limit?: Utils.boolify_mask(mask, @past_limit_flag),
      pre_open?: Utils.boolify_mask(mask, @pre_open_flag),
      should_tick_for_size?: TickTypes.size_related_type?(tick_type)
    }

    {:ok, msg}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defp decode_tick_type(type_str) do
    case TickTypes.to_atom(type_str) do
      {:ok, type} -> type
      _ -> :error
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
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
