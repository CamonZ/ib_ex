defmodule IbEx.Client.Messages.TickByTickData.TickByTickTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.TickByTickData.TickByTick

  alias IbEx.Client.Types.Trade
  alias IbEx.Client.Types.BidAsk
  alias IbEx.Client.Types.MidPoint

  describe "from_fields/1" do
    test "parses Trade data for Last & AllLast tick types" do
      assert {:ok, msg} = TickByTick.from_fields(["90001", "1", "1701251310", "3.25", "23", "2", "ARCA", "TI"])

      assert msg.request_id == "90001"
      assert match?(%Trade{}, msg.tick)
    end

    test "parses data for BidAsk tick type" do
      assert {:ok, msg} = TickByTick.from_fields(["90002", "3", "1609459200", "100.50", "101.50", "200", "150", "3"])

      assert msg.request_id == "90002"
      assert match?(%BidAsk{}, msg.tick)
    end

    test "parses data for MidPoint tick type" do
      assert {:ok, msg} = TickByTick.from_fields(["90003", "4", "1609459200", "101.00"])

      assert msg.request_id == "90003"
      assert match?(%MidPoint{}, msg.tick)
    end

    test "returns error for invalid tick types" do
      assert {:error, :invalid_args} == TickByTick.from_fields(["1004", "5", "other", "data"])
    end

    test "returns error for incomplete or invalid arguments" do
      assert TickByTick.from_fields([]) == {:error, :invalid_args}
      assert TickByTick.from_fields(["1005"]) == {:error, :invalid_args}
    end
  end
end
