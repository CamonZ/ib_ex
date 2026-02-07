defmodule IbEx.Client.Types.HistoricalTickLastTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.HistoricalTickLast

  describe "new/0" do
    test "creates a HistoricalTickLast struct with default attributes" do
      assert HistoricalTickLast.new() == %HistoricalTickLast{
               time: nil,
               mask: nil,
               price: nil,
               size: nil,
               exchange: nil,
               conditions: nil,
               past_limit: nil,
               unreported: nil
             }
    end
  end

  describe "new/1" do
    test "creates a HistoricalTickLast struct from a map with all fields" do
      params = %{
        time: 1_704_067_200,
        mask: 1,
        price: 150.75,
        size: Decimal.new("100"),
        exchange: "NYSE",
        conditions: "cond1",
        past_limit: true,
        unreported: false
      }

      result = HistoricalTickLast.new(params)

      assert result.time == 1_704_067_200
      assert result.mask == 1
      assert result.price == 150.75
      assert result.size == Decimal.new("100")
      assert result.exchange == "NYSE"
      assert result.conditions == "cond1"
      assert result.past_limit == true
      assert result.unreported == false
    end

    test "creates a HistoricalTickLast struct from a keyword list" do
      params = [
        time: 1_704_067_200,
        price: 150.75,
        exchange: "NYSE"
      ]

      result = HistoricalTickLast.new(params)

      assert result.time == 1_704_067_200
      assert result.price == 150.75
      assert result.exchange == "NYSE"
      assert result.mask == nil
      assert result.past_limit == nil
      assert result.unreported == nil
    end
  end
end
