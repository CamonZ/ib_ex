defmodule IbEx.Client.Messages.MarketData.TickSize do
  @moduledoc """
  One of the subscription messages coming from subscribing to
  the market data request.

  Represents the size of a tick, bid, ask, last or its delayed variants
  """

  defstruct request_id: nil,
            tick_type: nil,
            size: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          tick_type: atom(),
          size: Decimal.t() | nil
        }

  alias IbEx.Client.Utils
  alias IbEx.Client.Constants.TickTypes
  alias IbEx.Client.Protocols.Traceable

  def from_fields([_, request_id, tick_type_str, size]) do
    tick_type = decode_tick_type(tick_type_str)

    msg = %__MODULE__{
      request_id: request_id,
      tick_type: tick_type,
      size: Utils.to_decimal(size)
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

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %MarketData.TickSize{request_id: #{msg.request_id}, tick_type: #{msg.tick_type}, size: #{msg.size}}"
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
