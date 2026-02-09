defmodule IbEx.Client.Types.TradingSession do
  @moduledoc """
  Represents a single trading session entry parsed from the trading_hours or
  liquid_hours string on ContractDetails.

  Each entry in the semicolon-delimited string is either:
  - A closed day: `"20260208:CLOSED"`
  - A time range: `"20260209:0400-20260209:2000"`

  The timezone is not stored here -- it lives on `ContractDetails.time_zone_id`.
  """

  defstruct date: nil,
            status: nil,
            open: nil,
            close: nil

  @type t :: %__MODULE__{
          date: Date.t() | nil,
          status: :open | :closed,
          open: Time.t() | nil,
          close: Time.t() | nil
        }

  @doc """
  Parses a single trading session entry string.

  ## Examples

      iex> TradingSession.parse("20260208:CLOSED")
      {:ok, %TradingSession{date: ~D[2026-02-08], status: :closed, open: nil, close: nil}}

      iex> TradingSession.parse("20260209:0400-20260209:2000")
      {:ok, %TradingSession{date: ~D[2026-02-09], status: :open, open: ~T[04:00:00], close: ~T[20:00:00]}}
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_format}
  def parse(<<date::binary-size(8), ":CLOSED">>) do
    with {:ok, date} <- parse_date(date) do
      {:ok, %__MODULE__{date: date, status: :closed}}
    end
  end

  def parse(<<open_part::binary-size(13), "-", close_part::binary-size(13)>>) do
    with {:ok, open_date, open_time} <- parse_datetime(open_part),
         {:ok, _close_date, close_time} <- parse_datetime(close_part) do
      {:ok, %__MODULE__{date: open_date, status: :open, open: open_time, close: close_time}}
    end
  end

  def parse(entry) when is_binary(entry), do: {:error, :invalid_format}

  def parse(_), do: {:error, :invalid_format}

  defp parse_date(<<year::binary-size(4), month::binary-size(2), day::binary-size(2)>>) do
    with {y, ""} <- Integer.parse(year),
         {m, ""} <- Integer.parse(month),
         {d, ""} <- Integer.parse(day) do
      Date.new(y, m, d)
    else
      _ -> {:error, :invalid_format}
    end
  end

  defp parse_date(_), do: {:error, :invalid_format}

  defp parse_datetime(<<date::binary-size(8), ":", time::binary-size(4)>>) do
    with {:ok, date} <- parse_date(date),
         {:ok, time} <- parse_time(time) do
      {:ok, date, time}
    end
  end

  defp parse_datetime(_), do: {:error, :invalid_format}

  defp parse_time(<<hour::binary-size(2), minute::binary-size(2)>>) do
    with {h, ""} <- Integer.parse(hour),
         {m, ""} <- Integer.parse(minute) do
      Time.new(h, m, 0)
    else
      _ -> {:error, :invalid_format}
    end
  end

  defp parse_time(_), do: {:error, :invalid_format}
end
