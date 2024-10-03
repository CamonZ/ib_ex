defmodule IbEx.Client.Messages.MarketData.RequestCancelDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestCancelData
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  @request_id 1000
  describe "new/1" do
    test "creates a RequestCancelData struct" do
      assert {:ok, msg} = RequestCancelData.new(@request_id)

      assert msg.message_id == 2
      assert msg.version == 2
      assert msg.request_id == @request_id
    end
  end

  describe "String.Chars implementation" do
    test "converts the mesasge to a serializable binary" do
      msg = %RequestCancelData{message_id: 2, version: 2, request_id: @request_id}
      assert to_string(msg) == <<50, 0, 50, 0, 49, 48, 48, 48, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspects RequestCancelData struct correctly" do
      msg = %RequestCancelData{request_id: @request_id}
      assert inspect(msg) == "--> %MarketData.RequestCancelData{request_id: #{@request_id}}"
    end
  end

  describe "Subscribable" do
    test "subscribe/3 unsubscribes incoming messages with the given request id to the given pid" do
      table_ref = Subscriptions.initialize()
      :ets.insert(table_ref, {to_string(@request_id), self()})
      {:ok, msg} = RequestCancelData.new(@request_id)
      assert msg.request_id == @request_id

      assert {:ok, _msg} = Subscribable.subscribe(msg, self(), table_ref)

      assert {:error, :missing_subscription} == Subscriptions.reverse_lookup(table_ref, self())
    end
  end
end
