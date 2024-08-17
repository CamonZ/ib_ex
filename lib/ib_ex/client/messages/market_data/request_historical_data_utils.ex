defmodule IbEx.Client.Messages.MarketData.RequestHistoricalData.Utils do
  @moduledoc """
  Utils for constructing a valid HistoricalData Request
  """
  alias IbEx.Client.Messages.MarketData.RequestHistoricalData, as: Types

  @spec format_end_date_time(Types.end_date_time_type()) :: String.t() | :bad_arguments
  def format_end_date_time(%DateTime{} = unit) do
    unit
    |> DateTime.to_string()
    |> String.replace("-", "")
  end

  def format_end_date_time(nil), do: ""
  def format_end_date_time(_), do: :bad_arguments

  @duration_units ~w|second day week month year|a
  def get_valid_duration_units(), do: @duration_units

  @spec duration_unit_to_string(Types.duration_unit()) :: String.t() | :bad_arguments
  defp duration_unit_to_string(:second), do: "S"
  defp duration_unit_to_string(:day), do: "D"
  defp duration_unit_to_string(:week), do: "W"
  defp duration_unit_to_string(:month), do: "M"
  defp duration_unit_to_string(:year), do: "Y"
  defp duration_unit_to_string(_), do: :bad_arguments

  @spec format_duration(Types.duration_type()) :: String.t()
  def format_duration({step, _unit}) when step < 1, do: :bad_arguments
  def format_duration({_step, unit}) when unit not in @duration_units, do: :bad_arguments

  def format_duration({step, unit}) do
    unit = duration_unit_to_string(unit)
    "#{to_string(step)} #{unit}"
  end

  def format_duration(_), do: :bad_arguments

  @bar_size_units ~w|second minute hour day week month|a
  def get_valid_bar_size_units(), do: @bar_size_units

  def get_valid_bar_sizes(unit) when unit not in @bar_size_units, do: :bad_arguments
  def get_valid_bar_sizes(:second), do: [1, 5, 10, 15, 30]
  def get_valid_bar_sizes(:minute), do: [1, 2, 3, 5, 10, 15, 20, 30]
  def get_valid_bar_sizes(:hour), do: [1, 2, 3, 4, 8]
  def get_valid_bar_sizes(:day), do: [1]
  def get_valid_bar_sizes(:week), do: [1]
  def get_valid_bar_sizes(:month), do: [1]

  @spec bar_size_unit_to_string(Types.bar_size_unit()) :: String.t() | :bad_arguments
  defp bar_size_unit_to_string(:second), do: "sec"
  defp bar_size_unit_to_string(:minute), do: "min"
  defp bar_size_unit_to_string(:hour), do: "hour"
  defp bar_size_unit_to_string(:day), do: "day"
  defp bar_size_unit_to_string(:week), do: "week"
  defp bar_size_unit_to_string(:month), do: "month"
  defp bar_size_unit_to_string(_), do: :bad_arguments

  @spec format_bar_size(Types.bar_size_type()) :: String.t()
  def format_bar_size({step, _unit}) when step < 1, do: :bad_arguments
  def format_bar_size({_step, unit}) when unit not in @bar_size_units, do: :bad_arguments

  def format_bar_size({step, unit}) do
    unit = bar_size_unit_to_string(unit)
    unit = if step == 1, do: unit, else: unit <> "s"
    "#{to_string(step)} #{unit}"
  end

  def format_bar_size(_), do: :bad_arguments

  @spec format_what_to_show(Types.historical_bar_type()) :: String.t()
  def format_what_to_show(atom) when is_atom(atom), do: String.upcase(Kernel.to_string(atom))
  def format_what_to_show(_), do: :bad_arguments

  @spec bool_to_int(boolean()) :: 0..1 | :bad_arguments
  def bool_to_int(value) when not is_boolean(value), do: :bad_arguments
  def bool_to_int(value), do: (value && 1) || 0
end
