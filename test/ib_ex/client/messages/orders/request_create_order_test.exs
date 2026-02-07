defmodule IbEx.Client.Messages.Orders.RequestCreateOrderTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.{Order, Contract}
  alias IbEx.Client.Messages.Orders.RequestCreateOrder
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  @order_id 123
  @order Order.new(%{
           action: "BUY",
           total_quantity: 1,
           order_type: "MKT"
         })
  @contract Contract.new(%{symbol: "AAPL", security_type: "STK", currency: "USD"})

  describe "new/1" do
    test "creates a RequestCreateOrder struct with valid attributes" do
      assert {:ok, msg} = RequestCreateOrder.new(@order_id, @order, @contract)

      assert msg.message_id == 3
      assert msg.order == @order
      assert msg.contract == @contract
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      msg = %RequestCreateOrder{order_id: @order_id, order: @order, contract: @contract}

      contract_str = Enum.join(Contract.serialize(@contract, false), ", ")

      assert Traceable.to_s(msg) ==
               """
               --> RequestCreateOrder{
                 order_id: 123,
                 order: %Order{
                   action: BUY,
                   total_quantity: 1,
                   order_type: MKT
                 },
                 contract: #{contract_str}
               }
               """
    end
  end

  describe "Subscribable" do
    test "subscribes the message" do
      pid = self()
      table_ref = Subscriptions.initialize()
      {:ok, msg} = RequestCreateOrder.new(@order_id, @order, @contract)
      {:ok, subscribed_msg} = Subscribable.subscribe(msg, pid, table_ref)
      assert {:ok, ^pid} = Subscribable.lookup(subscribed_msg, table_ref)
    end
  end
end
