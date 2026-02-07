defmodule IbEx.Client.Types.HistogramEntryTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.HistogramEntry

  describe "new/0" do
    test "creates a HistogramEntry struct with default attributes" do
      assert HistogramEntry.new() == %HistogramEntry{
               price: nil,
               size: nil
             }
    end
  end

  describe "new/1" do
    test "creates a HistogramEntry struct from a map" do
      params = %{
        price: 150.50,
        size: Decimal.new("5000")
      }

      result = HistogramEntry.new(params)

      assert result.price == 150.50
      assert result.size == Decimal.new("5000")
    end

    test "creates a HistogramEntry struct from a keyword list" do
      params = [price: 150.50]

      result = HistogramEntry.new(params)

      assert result.price == 150.50
      assert result.size == nil
    end
  end
end
