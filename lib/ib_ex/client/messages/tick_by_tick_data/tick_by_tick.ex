defmodule IbEx.Client.Messages.TickByTickData.TickByTick do
  @moduledoc """
  Message received with data from the tick by tick data subscription request.

  Parsing is dependent on the type of TickByTick subscription (Last, AllLast, BidAsk, MidPoint)

  Fields in the frame are:

  message id, request id, tick type, time, price, size, mask, exchange, conditions 
  """

  defstruct request_id: nil, tick: nil

  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Protocols.Subscribable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- TickByTick{request_id: #{msg.request_id}, tick: #{inspect(msg.tick)}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
