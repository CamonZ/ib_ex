defmodule IbEx.Client.Types.OrderState.MarginInfoTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.OrderState.MarginInfo

  describe "new/0" do
    test "creates a MarginInfo struct with default attributes" do
      assert MarginInfo.new() == %MarginInfo{
               init_margin_before: nil,
               init_margin_change: nil,
               init_margin_after: nil,
               maint_margin_before: nil,
               maint_margin_change: nil,
               maint_margin_after: nil,
               equity_with_loan_before: nil,
               equity_with_loan_change: nil,
               equity_with_loan_after: nil,
               init_margin_before_outside_rth: nil,
               init_margin_change_outside_rth: nil,
               init_margin_after_outside_rth: nil,
               maint_margin_before_outside_rth: nil,
               maint_margin_change_outside_rth: nil,
               maint_margin_after_outside_rth: nil,
               equity_with_loan_before_outside_rth: nil,
               equity_with_loan_change_outside_rth: nil,
               equity_with_loan_after_outside_rth: nil
             }
    end
  end

  describe "new/1" do
    test "creates a MarginInfo struct from a map with RTH margin values" do
      params = %{
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

      result = MarginInfo.new(params)

      assert result.init_margin_before == "10000.00"
      assert result.init_margin_change == "500.00"
      assert result.init_margin_after == "10500.00"
      assert result.maint_margin_before == "8000.00"
      assert result.maint_margin_change == "400.00"
      assert result.maint_margin_after == "8400.00"
      assert result.equity_with_loan_before == "50000.00"
      assert result.equity_with_loan_change == "-500.00"
      assert result.equity_with_loan_after == "49500.00"
    end

    test "creates a MarginInfo struct from a map with outside RTH margin values" do
      params = %{
        init_margin_before_outside_rth: "12000.00",
        init_margin_change_outside_rth: "600.00",
        init_margin_after_outside_rth: "12600.00",
        maint_margin_before_outside_rth: "9600.00",
        maint_margin_change_outside_rth: "480.00",
        maint_margin_after_outside_rth: "10080.00",
        equity_with_loan_before_outside_rth: "50000.00",
        equity_with_loan_change_outside_rth: "-600.00",
        equity_with_loan_after_outside_rth: "49400.00"
      }

      result = MarginInfo.new(params)

      assert result.init_margin_before_outside_rth == "12000.00"
      assert result.init_margin_change_outside_rth == "600.00"
      assert result.init_margin_after_outside_rth == "12600.00"
      assert result.maint_margin_before_outside_rth == "9600.00"
      assert result.maint_margin_change_outside_rth == "480.00"
      assert result.maint_margin_after_outside_rth == "10080.00"
      assert result.equity_with_loan_before_outside_rth == "50000.00"
      assert result.equity_with_loan_change_outside_rth == "-600.00"
      assert result.equity_with_loan_after_outside_rth == "49400.00"
    end

    test "creates a MarginInfo struct from a keyword list" do
      params = [
        init_margin_before: "10000.00",
        maint_margin_before: "8000.00",
        equity_with_loan_before: "50000.00"
      ]

      result = MarginInfo.new(params)

      assert result.init_margin_before == "10000.00"
      assert result.maint_margin_before == "8000.00"
      assert result.equity_with_loan_before == "50000.00"
      assert result.init_margin_change == nil
    end
  end
end
