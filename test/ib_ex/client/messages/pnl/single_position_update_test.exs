defmodule IbEx.Client.Messages.Pnl.SinglePositionUpdateTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.Pnl.SinglePositionUpdate

  describe "from_fields/1" do
    test "returns the parsed message with the PnL for the given position" do
      assert {:ok, msg} =
               SinglePositionUpdate.from_fields(["90004", "0", "1.665208", "1.7976931348623157E308", "1.665208", "0.0"])

      assert msg.request_id == "90004"
      assert msg.position == 0
      assert msg.daily_pnl == Decimal.new("1.665208")
      assert msg.unrealized_pnl == Decimal.new("0")
      assert msg.realized_pnl == Decimal.new("1.665208")
      assert msg.value == Decimal.new("0.0")
    end

    test "returns error on invalid input" do
      assert {:error, :invalid_args} = SinglePositionUpdate.from_fields(["invalid", "data"])
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the struct" do
      pnl_single = %SinglePositionUpdate{
        request_id: "12345",
        position: "100",
        daily_pnl: Decimal.new("10.5"),
        unrealized_pnl: Decimal.new("5.25"),
        realized_pnl: Decimal.new("15.75"),
        value: Decimal.new("500")
      }

      assert inspect(pnl_single) ==
               """
               <-- Pnl.SinglePositionUpdate{
                 request_id: 12345,
                 position: 100,
                 daily_pnl: 10.5,
                 unrealized_pnl: 5.25,
                 realized_pnl: 15.75,
                 value: 500
               }
               """
    end
  end
end
