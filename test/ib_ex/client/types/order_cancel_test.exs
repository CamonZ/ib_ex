defmodule IbEx.Client.Types.OrderCancelTest do
  use ExUnit.Case, async: true
  alias IbEx.Client.Types.OrderCancel

  describe "new/0" do
    test "creates a OrderCancel struct with default attributes" do
      assert OrderCancel.new() == %OrderCancel{
               manual_order_cancel_time: nil,
               ext_operator: nil,
               external_user_id: nil,
               manual_order_indicator: :unset_integer
             }
    end
  end
end
