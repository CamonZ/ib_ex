defmodule IbEx.Client.Messages.MarketData.TickStringTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickString
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "creates TickString struct with valid fields" do
      assert {:ok, msg} = TickString.from_fields(["", "9001", "45", "1702662249"])

      assert msg.request_id == "9001"
      assert msg.tick_type == :last_timestamp
      assert msg.value == "1702662249"
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == TickString.from_fields(["123", "1"])
    end
  end

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
      {:ok, msg} = TickString.from_fields(["", "1", "45", "1702662249"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
