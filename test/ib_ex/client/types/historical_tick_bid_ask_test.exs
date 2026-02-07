defmodule IbEx.Client.Types.HistoricalTickBidAskTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.HistoricalTickBidAsk

  describe "new/0" do
    test "creates a HistoricalTickBidAsk struct with default attributes" do
      assert HistoricalTickBidAsk.new() == %HistoricalTickBidAsk{
               time: nil,
               mask: nil,
               bid_price: nil,
               ask_price: nil,
               bid_size: nil,
               ask_size: nil,
               ask_past_high: nil,
               bid_past_low: nil
             }
    end
  end

  describe "new/1" do
    test "creates a HistoricalTickBidAsk struct from a map with all fields" do
      params = %{
        time: 1_704_067_200,
        mask: 3,
        bid_price: 150.00,
        ask_price: 150.50,
        bid_size: Decimal.new("200"),
        ask_size: Decimal.new("300"),
        ask_past_high: true,
        bid_past_low: true
      }

      result = HistoricalTickBidAsk.new(params)

      assert result.time == 1_704_067_200
      assert result.mask == 3
      assert result.bid_price == 150.00
      assert result.ask_price == 150.50
      assert result.bid_size == Decimal.new("200")
      assert result.ask_size == Decimal.new("300")
      assert result.ask_past_high == true
      assert result.bid_past_low == true
    end

    test "creates a HistoricalTickBidAsk struct from a keyword list" do
      params = [
        time: 1_704_067_200,
        bid_price: 150.00,
        ask_price: 150.50
      ]

      result = HistoricalTickBidAsk.new(params)

      assert result.time == 1_704_067_200
      assert result.bid_price == 150.00
      assert result.ask_price == 150.50
      assert result.mask == nil
      assert result.ask_past_high == nil
      assert result.bid_past_low == nil
    end
  end
end
