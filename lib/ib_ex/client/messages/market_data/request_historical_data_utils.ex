defmodule IbEx.Client.Messages.MarketData.RequestHistoricalData.Utils do
  alias IbEx.Client.Messages.MarketData.RequestHistoricalData, as: Types
  @spec format_end_date_time(Types.end_date_time_type()) :: String.t() | :not_implemented
  def format_end_date_time(%DateTime{} = unit) do
    unit
    |> DateTime.to_string()
    |> String.replace("_", "")
  end

  def format_end_date_time(nil), do: ""
  def format_end_date_time(_), do: :not_implemented

  @spec duration_unit_to_string(Types.duration_unit()) :: String.t() | :not_implemented
  def duration_unit_to_string(:second), do: "S"
  def duration_unit_to_string(:day), do: "D"
  def duration_unit_to_string(:week), do: "W"
  def duration_unit_to_string(:month), do: "M"
  def duration_unit_to_string(:year), do: "Y"
  def duration_unit_to_string(_), do: :not_implemented

  @spec format_duration(Types.duration_type()) :: String.t()
  def format_duration({step, unit}) do
    unit = duration_unit_to_string(unit)
    "#{to_string(step)} #{unit}"
  end

  @spec bar_size_unit_to_string(Types.bar_size_unit()) :: String.t() | :not_implemented
  def bar_size_unit_to_string(:second), do: "sec"
  def bar_size_unit_to_string(:minute), do: "min"
  def bar_size_unit_to_string(:hour), do: "hour"
  def bar_size_unit_to_string(:day), do: "day"
  def bar_size_unit_to_string(:week), do: "week"
  def bar_size_unit_to_string(:month), do: "month"
  def bar_size_unit_to_string(_), do: :not_implemented

  @spec format_bar_size(Types.bar_size_type()) :: String.t()
  def format_bar_size({step, unit}) do
    unit = bar_size_unit_to_string(unit)
    unit = if step == 1, do: unit, else: unit <> "s"
    "#{to_string(step)} #{unit}"
  end

  @spec format_what_to_show(Types.historical_bar_type()) :: String.t()
  def format_what_to_show(atom), do: String.upcase(Kernel.to_string(atom))

  @spec bool_to_int(boolean()) :: 0..1
  def bool_to_int(value), do: (value && 1) || 0

  def get_available_bar_sizes(_bar_size_unit), do: :implement
end
