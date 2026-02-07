defmodule IbEx.Client.Types.OrderAllocationTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.OrderAllocation

  describe "new/0" do
    test "creates an OrderAllocation struct with default attributes" do
      assert OrderAllocation.new() == %OrderAllocation{
               account: nil,
               position: nil,
               position_desired: nil,
               position_after: nil,
               desired_alloc_qty: nil,
               allowed_alloc_qty: nil,
               is_monetary: false
             }
    end
  end

  describe "new/1" do
    test "creates an OrderAllocation struct from a map with valid attributes" do
      params = %{
        account: "DU12345",
        position: Decimal.new("100"),
        position_desired: Decimal.new("150"),
        position_after: Decimal.new("150"),
        desired_alloc_qty: Decimal.new("50"),
        allowed_alloc_qty: Decimal.new("50"),
        is_monetary: false
      }

      result = OrderAllocation.new(params)

      assert result.account == "DU12345"
      assert result.position == Decimal.new("100")
      assert result.position_desired == Decimal.new("150")
      assert result.position_after == Decimal.new("150")
      assert result.desired_alloc_qty == Decimal.new("50")
      assert result.allowed_alloc_qty == Decimal.new("50")
      assert result.is_monetary == false
    end

    test "creates an OrderAllocation struct with monetary allocation" do
      params = %{
        account: "DU67890",
        position: Decimal.new("0"),
        position_desired: Decimal.new("10000"),
        position_after: Decimal.new("10000"),
        desired_alloc_qty: Decimal.new("10000"),
        allowed_alloc_qty: Decimal.new("10000"),
        is_monetary: true
      }

      result = OrderAllocation.new(params)

      assert result.account == "DU67890"
      assert result.is_monetary == true
      assert result.desired_alloc_qty == Decimal.new("10000")
    end

    test "creates an OrderAllocation struct from a keyword list" do
      params = [
        account: "DU12345",
        position: Decimal.new("100"),
        is_monetary: false
      ]

      result = OrderAllocation.new(params)

      assert result.account == "DU12345"
      assert result.position == Decimal.new("100")
      assert result.is_monetary == false
      assert result.position_desired == nil
    end
  end
end
