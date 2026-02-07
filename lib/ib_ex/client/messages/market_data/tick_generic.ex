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

  alias IbEx.Client.Protocols.Traceable

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
