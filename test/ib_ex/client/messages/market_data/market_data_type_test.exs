defmodule IbEx.Client.Messages.MarketData.MarketDataTypeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.MarketDataType

  describe "from_fields/1" do
    test "creates the message with valid fields for live data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", "9001", "1"])

      assert msg.request_id == "9001"
      assert msg.data_type == :live
    end

    test "creates the message with valid fields for frozen data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", "9001", "2"])

      assert msg.request_id == "9001"
      assert msg.data_type == :frozen
    end

    test "creates the message with valid fields for delayed data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", "9001", "3"])

      assert msg.request_id == "9001"
      assert msg.data_type == :delayed
    end

    test "creates the message with valid fields for delayed_frozen data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", "9001", "4"])

      assert msg.request_id == "9001"
      assert msg.data_type == :delayed_frozen
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == MarketDataType.from_fields(["123", "1"])
    end
  end

  describe "Inspect implementation" do
    test "inspects MarketDataType struct correctly" do
      msg = %MarketDataType{request_id: "9001", data_type: :live}
      assert inspect(msg) == "<-- %MarketData.MarketDataType{request_id: 9001, data_type: live}"
    end
  end
end
