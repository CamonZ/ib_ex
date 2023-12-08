defmodule IbEx.Client.Messages.MarketDepth.RequestExchangesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.RequestExchanges

  describe "new/0" do
    test "creates the message" do
      assert {:ok, request} = RequestExchanges.new()
      assert request.message_id == 82
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a binary correctly" do
      request = %RequestExchanges{message_id: 82}
      assert to_string(request) == <<56, 50, 0>>
    end
  end

  describe "inspect/2 " do
    test "returns a human-readable version of the message" do
      assert inspect(%RequestExchanges{}) == "--> RequestExchanges{}"
    end
  end
end
