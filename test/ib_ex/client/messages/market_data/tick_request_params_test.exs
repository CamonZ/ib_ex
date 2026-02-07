defmodule IbEx.Client.Messages.MarketData.TickRequestParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickRequestParams
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      msg = %TickRequestParams{
        request_id: "9001",
        min_tick: 0.01,
        bbo_exchange: "9c0001",
        snapshot_permissions: 1
      }

      assert Traceable.to_s(msg) ==
               "<-- %MarketData.TickRequestParams{request_id: 9001, min_tick: 0.01, bbo_exchange: 9c0001, snapshot_permissions: 1}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      msg = %TickRequestParams{request_id: "1", min_tick: 0.01, bbo_exchange: "9c0001", snapshot_permissions: 3}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
