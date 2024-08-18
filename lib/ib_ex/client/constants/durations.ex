defmodule IbEx.Client.Constants.Durations do
  @moduledoc """
  The Interactive Brokers Historical Market Data maintains a duration parameter which specifies the overall length of time that data can be collected. The duration specified will derive the bars of data that can then be collected.
  Used by: 
  * MarketData.RequestHistoricalData
  """

  @typedoc "Specifies unit of time to describe the overall length of time that data can be collected"
  @type unit_type :: :second | :day | :week | :month | :year
  @type t :: {non_neg_integer(), unit_type()}

  @durations %{
    second: "S",
    day: "D",
    week: "W",
    month: "M",
    year: "Y"
  }
  def durations, do: @durations

  @spec format(__MODULE__.t()) :: String.t()
  def format({step, _unit}) when step < 1, do: :invalid_args

  def format({step, unit}) do
    case Map.fetch(@durations, unit) do
      {:ok, unit} ->
        "#{to_string(step)} #{unit}"

      _ ->
        :invalid_args
    end
  end

  def format(_), do: :invalid_args
end
