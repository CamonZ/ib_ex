defmodule IbEx.Client.Messages.MarketDepth.CancelDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.CancelData

  describe "new/0" do
    test "creates the message" do
      assert {:ok, msg} = CancelData.new(90001, true)

      assert msg.message_id == 11
      assert msg.request_id == 90001
      assert msg.smart_depth?
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a binary correctly" do
      request = %CancelData{message_id: 11, request_id: 90001, smart_depth?: true}
      assert to_string(request) == <<49, 49, 0, 49, 0, 57, 48, 48, 48, 49, 0, 49, 0>>
    end
  end

  describe "inspect/2 " do
    test "returns a human-readable version of the message" do
      assert inspect(%CancelData{request_id: 90001}) ==
               """
               --> %MarketDepth.CancelData{
                 request_id: 90001,
                 smart_depth?: true
               }
               """
    end
  end
end
