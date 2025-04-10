defmodule IbEx.Client.Messages.TickByTickData.TickByTick do
  @moduledoc """
  Message received with data from the tick by tick data subscription request.

  Parsing is dependent on the type of TickByTick subscription (Last, AllLast, BidAsk, MidPoint)

  Fields in the frame are:

  message id, request id, tick type, time, price, size, mask, exchange, conditions 
  """

  defstruct request_id: nil, tick: nil

  alias IbEx.Client.Types.Trade
  alias IbEx.Client.Types.BidAsk
  alias IbEx.Client.Types.MidPoint
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Protocols.Subscribable

  def from_fields([request_id, tick_type | rest]) do
    case parse_data_fields(tick_type, rest) do
      {:ok, tick} -> {:ok, %__MODULE__{request_id: request_id, tick: tick}}
      _ -> {:error, :invalid_args}
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defp parse_data_fields(type, fields) when is_binary(type) do
    parse_data_fields(String.to_integer(type), fields)
  rescue
    _ -> {:error, :invalid_args}
  end

  defp parse_data_fields(type, fields) when type in [1, 2] do
    Trade.from_tick_by_tick(fields)
  end

  defp parse_data_fields(3, fields) do
    BidAsk.from_tick_by_tick(fields)
  end

  defp parse_data_fields(4, fields) do
    MidPoint.from_tick_by_tick(fields)
  end

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
