defmodule IbEx.Client.Messages.MarketData.TickPriceTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickPrice
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      msg = %TickPrice{
        request_id: "123",
        tick_type: :bid,
        price: 100.5,
        size: Decimal.new("200"),
        can_autoexecute?: true,
        past_limit?: false,
        pre_open?: true,
        should_tick_for_size?: false
      }

      assert Traceable.to_s(msg) ==
               """
               <-- %MarketData.TickPrice{
                 request_id: 123,
                 tick_type: bid,
                 price: 100.5,
                 size: 200,
                 can_autoexecute?: true,
                 past_limit?: false,
                 pre_open?: true,
                 should_tick_for_size?: false
               }
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      msg = %TickPrice{request_id: "1", tick_type: :bid, price: 100.5}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
