defmodule IbEx.Client.Types.HistoricalTickTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.HistoricalTick

  describe "new/0" do
    test "creates a HistoricalTick struct with default attributes" do
      assert HistoricalTick.new() == %HistoricalTick{
               time: nil,
               price: nil,
               size: nil
             }
    end
  end

  describe "new/1" do
    test "creates a HistoricalTick struct from a map" do
      params = %{
        time: 1_704_067_200,
        price: 150.25,
        size: Decimal.new("100")
      }

      result = HistoricalTick.new(params)

      assert result.time == 1_704_067_200
      assert result.price == 150.25
      assert result.size == Decimal.new("100")
    end

    test "creates a HistoricalTick struct from a keyword list" do
      params = [time: 1_704_067_200, price: 150.25]

      result = HistoricalTick.new(params)

      assert result.time == 1_704_067_200
      assert result.price == 150.25
      assert result.size == nil
    end
  end
end
