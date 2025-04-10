defmodule IbEx.Client.Types.TradeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Trade

  describe "from_tick_by_tick/1" do
    test "correctly creates a Trade struct" do
      {:ok, trade} = Trade.from_tick_by_tick(["1701251310", "3.25", "23", "2", "ARCA", "TI"])

      assert trade.timestamp == ~U[2023-11-29 09:48:30Z]
      assert trade.mask == 2
      assert trade.size == 23
      assert trade.price == 3.25
      assert trade.exchange == "ARCA"
      assert trade.conditions == "TI"
      refute trade.past_limit
      assert trade.unreported
    end
  end

  describe "from_historical_ticks_last/1" do
    test "correctly creates a Trade struct" do
      {:ok, trade} = Trade.from_historical_ticks_last(["1701251310", "2", "23", "3.25", "ARCA", "TI"])

      assert trade.timestamp == ~U[2023-11-29 09:48:30Z]
      assert trade.mask == 2
      assert trade.size == 23
      assert trade.price == 3.25
      assert trade.exchange == "ARCA"
      assert trade.conditions == "TI"
      refute trade.past_limit
      assert trade.unreported
    end

    test "returns invalid_args when called with invalid args" do
      {:error, :invalid_args} = Trade.from_historical_ticks_last([])
      {:error, :invalid_args} = Trade.from_historical_ticks_last("")
      {:error, :invalid_args} = Trade.from_historical_ticks_last(["1701251310000000", "2", "23", "3.25", "ARCA", "TI"])
      {:error, :invalid_args} = Trade.from_historical_ticks_last(["1701251310", "a", "b", "c", "ARCA", "TI"])
    end
  end
end
