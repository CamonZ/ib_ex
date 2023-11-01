defmodule IbEx.Client.Messages.MatchingSymbols.RequestTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.MatchingSymbols.Request

  describe "new/1" do
    test "returns a MatchingSymbols Request message" do
      assert {:ok, %Request{} = request} = Request.new(pattern: "AAPL", request_id: 1)

      assert request.request_id == 1
      assert request.pattern == "AAPL"
      assert request.message_id == 81
    end
  end

  describe "String.Chars" do
    test "to_string/1 returns the binary representation of the message" do
      {:ok, msg} = Request.new(pattern: "AAPL", request_id: 1)

      assert to_string(msg) == <<56, 49, 0, 49, 0, 65, 65, 80, 76, 0>>
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = Request.new(pattern: "AAPL", request_id: 1)

      assert inspect(msg) == "--> MatchingSymbols{id: 81, request_id: 1, pattern: AAPL}"
    end
  end
end
