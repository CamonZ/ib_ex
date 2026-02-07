defmodule IbEx.Client.Messages.Pnl.SinglePositionUpdateTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Pnl.SinglePositionUpdate
  alias IbEx.Client.Protocols.Traceable

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      pnl_single = %SinglePositionUpdate{
        request_id: "12345",
        position: "100",
        daily_pnl: Decimal.new("10.5"),
        unrealized_pnl: Decimal.new("5.25"),
        realized_pnl: Decimal.new("15.75"),
        value: Decimal.new("500")
      }

      assert Traceable.to_s(pnl_single) ==
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
