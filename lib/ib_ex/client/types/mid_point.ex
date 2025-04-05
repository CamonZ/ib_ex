defmodule IbEx.Client.Types.MidPoint do
  @moduledoc """
    Represents a MidPoint price from the Time & Sales feed
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct timestamp: nil, mid_point: nil

  def from_tick_by_tick([ts, mid_point]) do
    case DateTime.from_unix(String.to_integer(ts)) do
      {:ok, timestamp} ->
        {:ok, %__MODULE__{timestamp: timestamp, mid_point: Decimal.new(mid_point)}}

      _ ->
        {:error, :invalid_args}
    end
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def from_tick_by_tick(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(trade) do
      "%MidPoint{timestamp: #{trade.timestamp}, mid_point: #{trade.mid_point}}"
    end
  end
end
