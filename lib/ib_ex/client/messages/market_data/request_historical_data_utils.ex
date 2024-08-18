defmodule IbEx.Client.Messages.MarketData.RequestHistoricalData.Utils do
  @moduledoc """
  Utils for constructing a valid HistoricalData Request
  """
  alias IbEx.Client.Messages.MarketData.RequestHistoricalData, as: Types

  @spec format_end_date_time(Types.end_date_time_type()) :: String.t() | :invalid_args
  def format_end_date_time(%DateTime{} = unit) do
    unit
    |> DateTime.to_string()
    |> String.replace("-", "")
  end

  def format_end_date_time(nil), do: ""
  def format_end_date_time(_), do: :invalid_args

  @durations %{
    second: "S",
    day: "D",
    week: "W",
    month: "M",
    year: "Y"
  }
  def durations, do: @durations

  @spec format_duration(Types.duration_type()) :: String.t()
  def format_duration({step, _unit}) when step < 1, do: :invalid_args
  def format_duration({step, unit}) do
    case Map.fetch(@durations, unit) do
      {:ok, unit} -> 
            "#{to_string(step)} #{unit}"
      _ ->  :invalid_args
    end
  end
  def format_duration(_), do: :invalid_args

  @bar_size_units %{
        second: "sec",
        month: "month",
        day: "day",
        minute: "min",
        hour: "hour",
        week: "week"
      }
  def bar_size_units, do: @bar_size_units 

  @valid_bar_sizes %{
    second: [1, 5, 10, 15, 30],
    minute: [1, 2, 3, 5, 10, 15, 20, 30],
    hour: [1, 2, 3, 4, 8],
    day: [1],
    week: [1],
    month: [1],
  }
  
  @spec get_valid_bar_sizes(Types.bar_size_unit()) :: String.t() | :invalid_args
  def get_valid_bar_sizes(value) do
    case Map.fetch(@valid_bar_sizes, value) do
      {:ok, result} -> 
        result
      _ -> 
        :invalid_args
    end
  end

  @spec format_bar_size(Types.bar_size_type()) :: String.t()
  def format_bar_size({step, _unit}) when step < 1, do: :invalid_args
  def format_bar_size({step, unit}) do
    case Map.fetch(@bar_size_units, unit) do
      {:ok, unit} -> 
        unit = if step == 1, do: unit, else: unit <> "s"
        "#{to_string(step)} #{unit}"
      _ -> 
        :invalid_args
    end 
  end

  def format_bar_size(_), do: :invalid_args

  @spec format_what_to_show(Types.historical_bar_type()) :: String.t()
  def format_what_to_show(atom) when is_atom(atom), do: String.upcase(Kernel.to_string(atom))
  def format_what_to_show(_), do: :invalid_args

  @spec bool_to_int(boolean()) :: 0..1 | :invalid_args
  def bool_to_int(value) when not is_boolean(value), do: :invalid_args
  def bool_to_int(value), do: (value && 1) || 0
end
