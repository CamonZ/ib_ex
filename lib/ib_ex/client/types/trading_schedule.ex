defmodule IbEx.Client.Types.TradingSchedule do
  @moduledoc """
  Parses a semicolon-delimited trading hours or liquid hours string from
  ContractDetails into a list of `TradingSession` structs.

  Format: `"20260208:CLOSED;20260209:0400-20260209:2000;20260210:0400-20260210:2000"`
  """

  alias IbEx.Client.Types.TradingSession

  @doc """
  Parses a semicolon-delimited schedule string into a list of TradingSession structs.

  Returns an empty list for nil or empty string input.

  ## Examples

      iex> TradingSchedule.parse("20260208:CLOSED;20260209:0400-20260209:2000")
      [
        %TradingSession{date: ~D[2026-02-08], status: :closed, open: nil, close: nil},
        %TradingSession{date: ~D[2026-02-09], status: :open, open: ~T[04:00:00], close: ~T[20:00:00]}
      ]

      iex> TradingSchedule.parse(nil)
      []
  """
  @spec parse(binary() | nil) :: list(TradingSession.t())
  def parse(nil), do: []
  def parse(""), do: []

  def parse(schedule) when is_binary(schedule) do
    schedule
    |> String.split(";", trim: true)
    |> Enum.reduce([], fn entry, acc ->
      case TradingSession.parse(entry) do
        {:ok, session} -> [session | acc]
        {:error, _} -> acc
      end
    end)
    |> Enum.reverse()
  end
end
