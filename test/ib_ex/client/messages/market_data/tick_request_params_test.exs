defmodule IbEx.Client.Messages.MarketData.TickRequestParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickRequestParams
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "creates TickRequestParams struct with valid fields" do
      assert {:ok, msg} = TickRequestParams.from_fields(["90001", "0.01", "9c0001", "3"])

      assert msg.request_id == "90001"
      assert msg.min_tick == 0.01
      assert msg.bbo_exchange == "9c0001"
      assert msg.snapshot_permissions == 3
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == TickRequestParams.from_fields(["123", "0.01", "NASDAQ"])
    end
  end

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
      {:ok, msg} = TickRequestParams.from_fields(["1", "0.01", "9c0001", "3"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
