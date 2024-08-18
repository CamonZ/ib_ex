defmodule IbEx.Client.Constants.BarSizes do
  @moduledoc """
  Bar sizes dictate the data returned by historical bar requests. The bar size will dictate the scale over which the OHLC/V is returned to the API.

  Used by: 
  * MarketData.RequestHistoricalData
  """

  @typedoc "Values to create a valid historical bar size"
  @type unit_type :: :second | :minute | :hour | :day | :week | :month
  @type t :: {non_neg_integer(), unit_type()}

  @bar_size_units %{
    second: "sec",
    month: "month",
    day: "day",
    minute: "min",
    hour: "hour",
    week: "week"
  }
  def bar_size_units, do: @bar_size_units

  @valid_historical_bar_sizes %{
    second: [1, 5, 10, 15, 30],
    minute: [1, 2, 3, 5, 10, 15, 20, 30],
    hour: [1, 2, 3, 4, 8],
    day: [1],
    week: [1],
    month: [1]
  }

  @spec get_valid_historical_bar_sizes(unit_type()) :: String.t() | :invalid_args
  def get_valid_historical_bar_sizes(value) do
    case Map.fetch(@valid_historical_bar_sizes, value) do
      {:ok, result} ->
        result

      _ ->
        :invalid_args
    end
  end

  @spec format(__MODULE__.t()) :: String.t()
  def format({step, _unit}) when step < 1, do: :invalid_args

  def format({step, unit}) do
    case Map.fetch(@bar_size_units, unit) do
      {:ok, unit} ->
        unit = if step == 1, do: unit, else: unit <> "s"
        "#{to_string(step)} #{unit}"

      _ ->
        :invalid_args
    end
  end

  def format(_), do: :invalid_args
end
