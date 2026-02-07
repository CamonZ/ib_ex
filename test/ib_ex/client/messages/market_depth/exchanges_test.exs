defmodule IbEx.Client.Messages.MarketDepth.ExchangesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.Exchanges
  alias IbEx.Client.Types.MarketDepthDescription

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      description = %MarketDepthDescription{
        exchange: "NYSE",
        security_type: "STK"
      }

      assert Traceable.to_s(%Exchanges{items: [description]}) ==
               """
               <-- %MarketDepth.Exchanges{items: [%IbEx.Client.Types.MarketDepthDescription{exchange: \"NYSE\", security_type: \"STK\", listing_exchange: nil, service_data_type: nil, aggregate_group: nil}]}
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_modules(table_ref, [Exchanges], self())

      msg = %Exchanges{items: []}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
