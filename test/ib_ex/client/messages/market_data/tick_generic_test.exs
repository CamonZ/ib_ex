defmodule IbEx.Client.Messages.MarketData.TickGenericTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickGeneric

  describe "from_fields/1" do
    test "creates TickGeneric struct with valid fields" do
      assert {:ok, msg} = TickGeneric.from_fields(["", "9001", "49", "0.0"])

      assert msg.request_id == "9001"
      assert msg.tick_type == :halted
      assert msg.value == 0.0
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == TickGeneric.from_fields(["123", "1"])
    end
  end

  describe "Inspect implementation" do
    test "inspects TickSize struct correctly" do
      msg = %TickGeneric{
        request_id: "9001",
        tick_type: :halted,
        value: 0.0
      }

      assert inspect(msg) ==
               "<-- %MarketData.TickGeneric{request_id: 9001, tick_type: halted, value: 0.0}"
    end
  end
end
