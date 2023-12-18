defmodule IbEx.Client.Messages.MarketData.TickStringTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickString

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

  describe "Inspect implementation" do
    test "inspects TickSize struct correctly" do
      msg = %TickString{
        request_id: "9001",
        tick_type: :last_timestamp,
        value: "1702662249"
      }

      assert inspect(msg) ==
               "<-- %MarketData.TickString{request_id: 9001, tick_type: last_timestamp, value: 1702662249}"
    end
  end
end
