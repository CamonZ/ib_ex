defmodule IbEx.Client.Messages.Pnl.AllPositionsUpdateTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Pnl.AllPositionsUpdate
  alias IbEx.Client.Protocols.Traceable

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
