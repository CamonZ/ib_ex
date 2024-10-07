defmodule IbEx.Client.Messages.MarketData.Tick.StringTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.Tick.String
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "creates String struct with valid fields" do
      assert {:ok, msg} = String.from_fields(["", "9001", "45", "1702662249"])

      assert msg.request_id == "9001"
      assert msg.tick_type == :last_timestamp
      assert msg.value == "1702662249"
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == String.from_fields(["123", "1"])
    end
  end

  describe "Inspect implementation" do
    test "inspects TickSize struct correctly" do
      msg = %String{
        request_id: "9001",
        tick_type: :last_timestamp,
        value: "1702662249"
      }

      assert inspect(msg) ==
               "<-- %MarketData.Tick.String{request_id: 9001, tick_type: last_timestamp, value: 1702662249}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      {:ok, msg} = String.from_fields(["", "1", "45", "1702662249"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
