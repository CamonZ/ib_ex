defmodule IbEx.Client.Types.RealTimeBarTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.RealTimeBar

  describe "new/0" do
    test "creates a RealTimeBar struct with default attributes" do
      assert RealTimeBar.new() == %RealTimeBar{
               time: nil,
               end_time: nil,
               open: nil,
               high: nil,
               low: nil,
               close: nil,
               volume: nil,
               count: nil,
               wap: nil
             }
    end
  end

  describe "new/1" do
    test "creates a RealTimeBar struct from a map with valid attributes" do
      params = %{
        time: "20250115 10:30:00",
        end_time: "20250115 10:30:05",
        open: 150.25,
        high: 151.00,
        low: 149.50,
        close: 150.75,
        volume: Decimal.new("500"),
        count: 25,
        wap: Decimal.new("150.50")
      }

      result = RealTimeBar.new(params)

      assert result.time == "20250115 10:30:00"
      assert result.end_time == "20250115 10:30:05"
      assert result.open == 150.25
      assert result.high == 151.00
      assert result.low == 149.50
      assert result.close == 150.75
      assert result.volume == Decimal.new("500")
      assert result.count == 25
      assert result.wap == Decimal.new("150.50")
    end

    test "creates a RealTimeBar struct from a keyword list" do
      params = [
        time: "20250115 10:30:00",
        end_time: "20250115 10:30:05",
        open: 150.25,
        close: 150.75
      ]

      result = RealTimeBar.new(params)

      assert result.time == "20250115 10:30:00"
      assert result.end_time == "20250115 10:30:05"
      assert result.open == 150.25
      assert result.close == 150.75
      assert result.high == nil
      assert result.low == nil
      assert result.volume == nil
    end
  end
end
