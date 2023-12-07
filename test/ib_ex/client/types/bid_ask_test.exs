defmodule IbEx.Client.Types.BidAskTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.BidAsk

  describe "from_tick_by_tick/1" do
    test "creates a BidAsk struct with valid input" do
      assert {:ok, struct} = BidAsk.from_tick_by_tick(["1609459200", "100.50", "101.50", "200", "150", "3"])

      assert struct.timestamp == ~U[2021-01-01 00:00:00Z]
      assert struct.bid_price == Decimal.new("100.50")
      assert struct.ask_price == Decimal.new("101.50")
      assert struct.bid_size == 200
      assert struct.ask_size == 150
      assert struct.mask == 3
      assert struct.bid_past_low == true
      assert struct.ask_past_high == true
    end

    test "returns an error with invalid timestamp" do
      assert {:error, :invalid_args} == BidAsk.from_tick_by_tick(["invalid_ts", "100.50", "101.50", "200", "150", "3"])
    end

    test "returns an error with incomplete arguments" do
      assert {:error, :invalid_args} = BidAsk.from_tick_by_tick(["1609459200", "100.50", "101.50"])
    end
  end
end
