defmodule IbEx.Client.Constants.WhatToShow do
  @moduledoc """
  Describes the nature of the data being retrieved by: 
  * MarketData.RequestHistoricalData
  * MarketData.RequestRealtimeBarData <- not yet implemented
  """

  @typedoc "These values are used to request different data. Some bar types support more products than others"
  @type t ::
          :aggtrades
          | :ask
          | :bid
          | :bid_ask
          | :fee_rate
          | :historical_volatility
          | :midpoint
          | :option_implied_volatility
          | :schedule
          | :trades
          | :yield_ask
          | :yield_bid_ask
          | :yield_last

  @spec to_upcase_string(__MODULE__.t()) :: String.t() | :invalid_args
  def to_upcase_string(atom) when is_atom(atom), do: String.upcase(Kernel.to_string(atom))
  def to_upcase_string(_), do: :invalid_args

  @what_to_show ~w(aggtrades ask bid bid_ask fee_rate
          historical_volatility
          midpoint
          option_implied_volatility
          schedule
          trades
          yield_ask
          yield_bid_ask
          yield_last)a

  def what_to_show do
    @what_to_show
    |> Enum.zip(Enum.map(@what_to_show, &to_upcase_string/1))
    |> Enum.into(%{})
  end

  @spec format(__MODULE__.t()) :: String.t() | :invalid_args
  def format(atom) do
    case Map.fetch(what_to_show(), atom) do
      {:ok, result} ->
        result

      _ ->
        :invalid_args
    end
  end
end
