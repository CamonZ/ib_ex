defmodule IbEx.Client.Messages.MarketData.TickStringTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickString
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      msg = %TickString{
        request_id: "9001",
        tick_type: :last_timestamp,
        value: "1702662249"
      }

      assert Traceable.to_s(msg) ==
               "<-- %MarketData.TickString{request_id: 9001, tick_type: last_timestamp, value: 1702662249}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      msg = %TickString{request_id: "1", tick_type: :last_timestamp, value: "1702662249"}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
