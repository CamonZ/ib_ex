defmodule IbEx.Client.Messages.MarketData.TickGenericTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickGeneric
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      msg = %TickGeneric{
        request_id: "9001",
        tick_type: :halted,
        value: 0.0
      }

      assert Traceable.to_s(msg) ==
               "<-- %MarketData.TickGeneric{request_id: 9001, tick_type: halted, value: 0.0}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      msg = %TickGeneric{request_id: "1", tick_type: :halted, value: 0.0}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
