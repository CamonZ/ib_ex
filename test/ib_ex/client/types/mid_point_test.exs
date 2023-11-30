defmodule IbEx.Client.Types.MidPointTest do
  use ExUnit.Case
  alias IbEx.Client.Types.MidPoint

  describe "from_tick_by_tick/1" do
    test "creates a MidPoint struct with valid input" do
      assert {:ok, struct} = MidPoint.from_tick_by_tick(["1609459200", "123.45"])

      assert struct.timestamp == ~U[2021-01-01 00:00:00Z]
      assert struct.mid_point == Decimal.new("123.45")
    end

    test "returns an error with invalid timestamp" do
      assert {:error, :invalid_args} == MidPoint.from_tick_by_tick(["invalid_ts", "123.45"])
    end

    test "returns an error with invalid arguments" do
      assert {:error, :invalid_args} == MidPoint.from_tick_by_tick(["1609459200"])
    end
  end
end
