defmodule IbEx.Client.Types.PriceIncrementTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.PriceIncrement

  describe "new/0" do
    test "creates a PriceIncrement struct with default attributes" do
      assert PriceIncrement.new() == %PriceIncrement{
               low_edge: nil,
               increment: nil
             }
    end
  end

  describe "new/1" do
    test "creates a PriceIncrement struct from a map" do
      params = %{low_edge: 0.0, increment: 0.01}

      result = PriceIncrement.new(params)

      assert result.low_edge == 0.0
      assert result.increment == 0.01
    end

    test "creates a PriceIncrement struct from a keyword list" do
      params = [low_edge: 1.0, increment: 0.05]

      result = PriceIncrement.new(params)

      assert result.low_edge == 1.0
      assert result.increment == 0.05
    end
  end
end
