defmodule IbEx.Client.Messages.MarketDepth.RequestExchangesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.Exchanges
  alias IbEx.Client.Messages.MarketDepth.RequestExchanges
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

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

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      assert Traceable.to_s(%RequestExchanges{}) == "--> RequestExchanges{}"
    end
  end

  describe "Subscribable" do
    test "subscribe/3 subscribes incoming messages with the msg's request id to the given pid" do
      table_ref = Subscriptions.initialize()

      {:ok, msg} = RequestExchanges.new()

      assert {:ok, ^msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert {:ok, pid} = Subscriptions.lookup(table_ref, Exchanges)

      assert pid == self()
    end
  end
end
