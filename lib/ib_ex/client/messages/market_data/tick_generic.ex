defmodule IbEx.Client.Messages.MarketData.TickGeneric do
  @moduledoc """
  One of the subscription messages coming from subscribing to
  the market data request.

  Represents a generic tick.
  """

  defstruct request_id: nil,
            tick_type: nil,
            value: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          tick_type: atom(),
          value: float() | nil
        }

  alias IbEx.Client.Constants.TickTypes
  alias IbEx.Client.Utils
  alias IbEx.Client.Protocols.Traceable

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([_, request_id, tick_type_str, value]) do
    tick_type = decode_tick_type(tick_type_str)

    msg = %__MODULE__{
      request_id: request_id,
      tick_type: tick_type,
      value: Utils.to_float(value)
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
      "<-- %MarketData.TickGeneric{request_id: #{msg.request_id}, tick_type: #{msg.tick_type}, value: #{msg.value}}"
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
