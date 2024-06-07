defmodule IbEx.Client.Messages.MatchingSymbols.RequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MatchingSymbols.Request
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "new/1" do
    test "returns a MatchingSymbols Request message" do
      assert {:ok, %Request{} = request} = Request.new("AAPL")

      assert request.pattern == "AAPL"
      assert request.message_id == 81
    end
  end

  describe "String.Chars" do
    test "to_string/1 returns the binary representation of the message" do
      {:ok, msg} = Request.new("AAPL")
      msg = %{msg | request_id: 1}

      assert to_string(msg) == <<56, 49, 0, 49, 0, 65, 65, 80, 76, 0>>
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = Request.new("AAPL")
      msg = %{msg | request_id: 1}

      assert inspect(msg) == "--> MatchingSymbols{id: 81, request_id: 1, pattern: AAPL}"
    end
  end

  describe "Subscribable" do
    test "subscribe/2 subscribes incoming messages with the msg's request id to the given pid" do
      table_ref = Subscriptions.initialize()

      {:ok, msg} = Request.new("AAPL")

      assert {:ok, msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert msg.request_id == 1

      assert {:ok, pid} = Subscriptions.lookup(table_ref, to_string(msg.request_id))

      assert pid == self()
    end
  end
end
