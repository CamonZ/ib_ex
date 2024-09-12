defmodule IbEx.Client.Types.FinancialAdvisorParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    FinancialAdvisorParams
  }

  describe "new/0" do
    test "creates a FinancialAdvisorParams struct with default attributes" do
      assert FinancialAdvisorParams.new() == %FinancialAdvisorParams{
               group_identifier: nil,
               method: nil,
               percentage: nil
             }
    end
  end

  describe "new/1" do
    test "creates a FinancialAdvisorParams struct with valid attributes" do
      attrs = %{
        group_identifier: "fa_group",
        method: "fa_method",
        percentage: "fa_percentage"
      }

      assert FinancialAdvisorParams.new(attrs) == %FinancialAdvisorParams{
               group_identifier: "fa_group",
               method: "fa_method",
               percentage: "fa_percentage"
             }
    end
  end

  describe "serialize/1" do
    test "serializes FinancialAdvisorParams" do
      attrs = %{
        group_identifier: "fa_group",
        method: "fa_method",
        percentage: "fa_percentage"
      }

      params = FinancialAdvisorParams.new(attrs)

      assert FinancialAdvisorParams.serialize(params) == [
               params.group_identifier,
               params.method,
               params.percentage
             ]
    end
  end
end
