defmodule IbEx.Client.Messages.Orders.RequestCreateOrderTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.{Order, Contract}
  alias IbEx.Client.Messages.Orders.RequestCreateOrder

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

  describe "String.Chars implementation" do
    test "converts the mesasge to a serializable binary" do
      msg = %RequestCreateOrder{order_id: @order_id, order: @order, contract: @contract}

      assert to_string(msg) ==
               <<0, 49, 50, 51, 0, 48, 0, 65, 65, 80, 76, 0, 83, 84, 75, 0, 0, 48, 46, 48, 0, 0, 0, 83, 77, 65, 82, 84,
                 0, 0, 85, 83, 68, 0, 0, 0, 0, 0, 66, 85, 89, 0, 49, 0, 77, 75, 84, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 49,
                 0, 48, 0, 48, 0, 48, 0, 48, 0, 48, 0, 48, 0, 48, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 45, 49, 0,
                 48, 0, 0, 0, 48, 0, 0, 0, 48, 0, 48, 0, 0, 48, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 48, 0, 0, 0, 48, 0, 48, 0, 0, 0, 48, 0, 0, 48, 0, 48, 0, 48, 0, 48, 0, 0, 49, 46, 55,
                 57, 55, 54, 57, 51, 49, 51, 52, 56, 54, 50, 51, 49, 53, 55, 101, 51, 48, 56, 0, 49, 46, 55, 57, 55, 54,
                 57, 51, 49, 51, 52, 56, 54, 50, 51, 49, 53, 55, 101, 51, 48, 56, 0, 49, 46, 55, 57, 55, 54, 57, 51, 49,
                 51, 52, 56, 54, 50, 51, 49, 53, 55, 101, 51, 48, 56, 0, 49, 46, 55, 57, 55, 54, 57, 51, 49, 51, 52, 56,
                 54, 50, 51, 49, 53, 55, 101, 51, 48, 56, 0, 49, 46, 55, 57, 55, 54, 57, 51, 49, 51, 52, 56, 54, 50, 51,
                 49, 53, 55, 101, 51, 48, 56, 0, 48, 0, 0, 0, 0, 49, 46, 55, 57, 55, 54, 57, 51, 49, 51, 52, 56, 54, 50,
                 51, 49, 53, 55, 101, 51, 48, 56, 0, 0, 0, 0, 0, 48, 0, 48, 0, 48, 0, 0, 50, 49, 52, 55, 52, 56, 51, 54,
                 52, 55, 0, 50, 49, 52, 55, 52, 56, 51, 54, 52, 55, 0, 48, 0, 0, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspects RequestCreateOrder struct correctly" do
      msg = %RequestCreateOrder{order_id: @order_id, order: @order, contract: @contract}

      contract_str = Enum.join(Contract.serialize(@contract, false), ", ")

      assert inspect(msg) ==
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
end
