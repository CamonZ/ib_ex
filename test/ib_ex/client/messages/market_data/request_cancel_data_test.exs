defmodule IbEx.Client.Messages.MarketData.RequestCancelDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestCancelData
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "new/1" do
    test "creates a RequestCancelData struct" do
      assert {:ok, msg} = RequestCancelData.new()

      assert msg.message_id == 2
      assert msg.version == 2
    end
  end

  describe "String.Chars implementation" do
    test "converts the mesasge to a serializable binary" do
      msg = %RequestCancelData{message_id: 2, version: 2, request_id: 1000}
      assert to_string(msg) == <<50, 0, 50, 0, 49, 48, 48, 48, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspects RequestCancelData struct correctly" do
      msg = %RequestCancelData{request_id: 1000}
      assert inspect(msg) == "--> %MarketData.RequestCancelData{request_id: 1000}"
    end
  end

  describe "Subscribable" do
    test "subscribe/2 unsubscribes incoming messages with the given request id to the given pid" do
      table_ref = Subscriptions.initialize()
      :ets.insert(table_ref, {"1", self()})
      {:ok, msg} = RequestCancelData.new()

      assert {:ok, msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert msg.request_id == "1"

      assert {:error, :missing_subscription} == Subscriptions.reverse_lookup(table_ref, self())
    end
  end
end
