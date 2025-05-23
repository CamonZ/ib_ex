defmodule IbEx.Client.Messages.Orders.RequestCancelOrderTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.OrderCancel
  alias IbEx.Client.Messages.Orders.RequestCancelOrder
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "new/1" do
    test "creates a RequestCancelOrder struct with order_id" do
      order_id = 123
      assert {:ok, msg} = RequestCancelOrder.new(order_id)

      assert msg == %RequestCancelOrder{
               message_id: 4,
               version: 1,
               order_id: order_id,
               order_cancel_params: %OrderCancel{
                 manual_order_cancel_time: nil,
                 ext_operator: nil,
                 external_user_id: nil,
                 manual_order_indicator: :unset_integer
               }
             }
    end
  end

  describe "new/2" do
    test "creates a RequestCancelOrder struct with valid parameters" do
      order_id = 123
      manual_order_cancel_time = "manual_order_cancel_time"
      params = OrderCancel.new(%{manual_order_cancel_time: manual_order_cancel_time})
      assert {:ok, msg} = RequestCancelOrder.new(order_id, params)

      assert msg == %RequestCancelOrder{
               message_id: 4,
               version: 1,
               order_id: order_id,
               order_cancel_params: %OrderCancel{
                 manual_order_cancel_time: manual_order_cancel_time,
                 ext_operator: nil,
                 external_user_id: nil,
                 manual_order_indicator: :unset_integer
               }
             }
    end
  end

  describe "String.Chars implementation" do
    test "converts the mesasge to a serializable binary" do
      msg = %RequestCancelOrder{message_id: 4, version: 1, order_id: 1000}
      assert to_string(msg) == <<52, 0, 49, 0, 49, 48, 48, 48, 0, 0, 0, 0, 50, 49, 52, 55, 52, 56, 51, 54, 52, 55, 0>>
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      msg = %RequestCancelOrder{order_id: 1000}
      assert Traceable.to_s(msg) == "--> %MarketData.RequestCancelOrder{order_id: 1000}"
    end
  end

  describe "Subscribable" do
    test "subscribe/3 unsubscribes incoming messages with the given request id to the given pid" do
      table_ref = Subscriptions.initialize()
      :ets.insert(table_ref, {"1", self()})
      {:ok, msg} = RequestCancelOrder.new(123)

      assert {:ok, msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert msg.request_id == "1"

      assert {:error, :missing_subscription} == Subscriptions.reverse_lookup(table_ref, self())
    end
  end
end
