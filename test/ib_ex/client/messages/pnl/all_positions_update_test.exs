defmodule IbEx.Client.Messages.Pnl.AllPositionsUpdateTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Pnl.AllPositionsUpdate
  alias IbEx.Client.Protocols.Traceable

  describe "from_fields/1" do
    test "returns the parsed message with the PnL for the given position" do
      assert {:ok, msg} = AllPositionsUpdate.from_fields(["90001", "-11.483693125", "0.0", "1.5298190129036"])

      assert msg.request_id == "90001"
      assert msg.daily_pnl == Decimal.new("-11.483693125")
      assert msg.unrealized_pnl == Decimal.new("0.0")
      assert msg.realized_pnl == Decimal.new("1.5298190129036")
    end

    test "returns error on invalid input" do
      assert {:error, :invalid_args} = AllPositionsUpdate.from_fields(["invalid", "data"])
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      pnl_single = %AllPositionsUpdate{
        request_id: "90001",
        daily_pnl: Decimal.new("-11.483693125"),
        unrealized_pnl: Decimal.new("0.0"),
        realized_pnl: Decimal.new("1.5298190129036")
      }

      assert Traceable.to_s(pnl_single) ==
               """
               <-- Pnl.AllPositionsUpdate{
                 request_id: 90001,
                 daily_pnl: -11.483693125,
                 unrealized_pnl: 0.0,
                 realized_pnl: 1.5298190129036
               }
               """
    end
  end
end
