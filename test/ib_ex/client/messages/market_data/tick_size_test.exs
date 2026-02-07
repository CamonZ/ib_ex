defmodule IbEx.Client.Messages.MarketData.TickSizeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickSize
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      msg = %TickSize{
        request_id: "123",
        tick_type: :bid_size,
        size: Decimal.new("200")
      }

      assert Traceable.to_s(msg) ==
               "<-- %MarketData.TickSize{request_id: 123, tick_type: bid_size, size: 200}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      msg = %TickSize{request_id: "1", tick_type: :bid_size, size: Decimal.new("200")}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
