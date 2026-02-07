defmodule IbEx.Client.Types.BarTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Bar

  describe "new/0" do
    test "creates a Bar struct with default attributes" do
      assert Bar.new() == %Bar{
               time: nil,
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
    test "creates a Bar struct from a map with valid attributes" do
      params = %{
        time: "20250115 10:30:00",
        open: 150.25,
        high: 151.00,
        low: 149.50,
        close: 150.75,
        volume: Decimal.new("1000"),
        count: 50,
        wap: Decimal.new("150.50")
      }

      result = Bar.new(params)

      assert result.time == "20250115 10:30:00"
      assert result.open == 150.25
      assert result.high == 151.00
      assert result.low == 149.50
      assert result.close == 150.75
      assert result.volume == Decimal.new("1000")
      assert result.count == 50
      assert result.wap == Decimal.new("150.50")
    end

    test "creates a Bar struct from a keyword list" do
      params = [
        time: "20250115 10:30:00",
        open: 150.25,
        high: 151.00,
        low: 149.50,
        close: 150.75
      ]

      result = Bar.new(params)

      assert result.time == "20250115 10:30:00"
      assert result.open == 150.25
      assert result.high == 151.00
      assert result.low == 149.50
      assert result.close == 150.75
      assert result.volume == nil
      assert result.count == nil
      assert result.wap == nil
    end
  end
end
