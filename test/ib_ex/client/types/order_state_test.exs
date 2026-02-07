defmodule IbEx.Client.Types.OrderStateTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.OrderState
  alias IbEx.Client.Types.OrderState.MarginInfo
  alias IbEx.Client.Types.OrderAllocation

  describe "new/0" do
    test "creates an OrderState struct with default attributes" do
      assert OrderState.new() == %OrderState{
               status: nil,
               margin: nil,
               commission: nil,
               min_commission: nil,
               max_commission: nil,
               commission_currency: nil,
               suggested_size: nil,
               reject_reason: nil,
               warning_text: nil,
               completed_time: nil,
               completed_status: nil,
               allocations: []
             }
    end
  end

  describe "new/1" do
    test "creates an OrderState struct from a map with valid attributes" do
      params = %{
        status: "PreSubmitted",
        commission: 1.75,
        min_commission: 1.0,
        max_commission: 2.5,
        commission_currency: "USD",
        suggested_size: Decimal.new("100"),
        reject_reason: "",
        warning_text: "Order will be held until market opens",
        completed_time: "20250115 10:30:00",
        completed_status: "Filled"
      }

      result = OrderState.new(params)

      assert result.status == "PreSubmitted"
      assert result.commission == 1.75
      assert result.min_commission == 1.0
      assert result.max_commission == 2.5
      assert result.commission_currency == "USD"
      assert result.suggested_size == Decimal.new("100")
      assert result.reject_reason == ""
      assert result.warning_text == "Order will be held until market opens"
      assert result.completed_time == "20250115 10:30:00"
      assert result.completed_status == "Filled"
      assert result.allocations == []
    end

    test "creates an OrderState struct with nested MarginInfo from a map" do
      params = %{
        status: "Submitted",
        margin: %{
          init_margin_before: "10000.00",
          init_margin_change: "500.00",
          init_margin_after: "10500.00",
          maint_margin_before: "8000.00",
          maint_margin_change: "400.00",
          maint_margin_after: "8400.00",
          equity_with_loan_before: "50000.00",
          equity_with_loan_change: "-500.00",
          equity_with_loan_after: "49500.00"
        }
      }

      result = OrderState.new(params)

      assert result.status == "Submitted"
      assert %MarginInfo{} = result.margin
      assert result.margin.init_margin_before == "10000.00"
      assert result.margin.init_margin_change == "500.00"
      assert result.margin.init_margin_after == "10500.00"
      assert result.margin.maint_margin_before == "8000.00"
      assert result.margin.equity_with_loan_before == "50000.00"
    end

    test "preserves an existing MarginInfo struct when passed directly" do
      margin = MarginInfo.new(%{init_margin_before: "15000.00"})

      params = %{
        status: "Submitted",
        margin: margin
      }

      result = OrderState.new(params)

      assert result.margin == margin
      assert result.margin.init_margin_before == "15000.00"
    end

    test "creates an OrderState struct with allocations list" do
      allocation_1 = OrderAllocation.new(%{account: "DU12345", position: Decimal.new("100")})
      allocation_2 = OrderAllocation.new(%{account: "DU67890", position: Decimal.new("200")})

      params = %{
        status: "Submitted",
        allocations: [allocation_1, allocation_2]
      }

      result = OrderState.new(params)

      assert length(result.allocations) == 2
      assert Enum.at(result.allocations, 0).account == "DU12345"
      assert Enum.at(result.allocations, 1).account == "DU67890"
    end

    test "creates an OrderState struct from a keyword list" do
      params = [
        status: "PreSubmitted",
        commission: 1.75,
        commission_currency: "USD"
      ]

      result = OrderState.new(params)

      assert result.status == "PreSubmitted"
      assert result.commission == 1.75
      assert result.commission_currency == "USD"
      assert result.margin == nil
    end

    test "does not construct MarginInfo when margin is nil" do
      params = %{status: "Submitted"}

      result = OrderState.new(params)

      assert result.margin == nil
    end
  end
end
