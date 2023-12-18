defmodule IbEx.Client.Messages.MarketData.RequestCancelDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestCancelData

  describe "new/1" do
    test "creates a RequestCancelData struct with valid request id" do
      assert {:ok, msg} = RequestCancelData.new("1000")

      assert msg.message_id == 2
      assert msg.version == 2
      assert msg.request_id == "1000"
    end
  end

  describe "String.Chars implementation" do
    test "converts the mesasge to a serializable binary" do
      msg = %RequestCancelData{message_id: 2, version: 2, request_id: "1000"}
      assert to_string(msg) == <<50, 0, 50, 0, 49, 48, 48, 48, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspects RequestCancelData struct correctly" do
      msg = %RequestCancelData{request_id: "1000"}
      assert inspect(msg) == "--> %MarketData.RequestCancelData{request_id: 1000}"
    end
  end
end
