defmodule IbEx.Client.Messages.MarketDepth.L2DataMultipleTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.L2DataMultiple
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      timestamp = DateTime.utc_now()

      msg = %L2DataMultiple{
        request_id: "90001",
        position: 1,
        market_maker: "NYSE",
        operation: "insert",
        side: "ask",
        price: 10.5,
        size: 100,
        smart_depth?: true,
        timestamp: timestamp
      }

      assert Traceable.to_s(msg) ==
               """
               <-- %MarketDepth.L2DataMultiple{
                 request_id: 90001,
                 position: 1,
                 market_maker: NYSE,
                 operation: insert,
                 side: ask,
                 price: 10.5,
                 size: 100,
                 smart_depth?: true,
                 timestamp: #{timestamp}
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      msg = %L2DataMultiple{request_id: "1"}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
