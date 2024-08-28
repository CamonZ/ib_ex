defmodule IbEx.Client.Types.BoxOrderParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.BoxOrderParams

  describe "new/0" do
    test "creates a BoxOrderParams struct with default attributes" do
      assert BoxOrderParams.new() == %BoxOrderParams{
               starting_price: nil,
               stock_reference_price: nil,
               delta: nil
             }
    end
  end

  describe "new/1" do
    test "creates a BoxOrderParams struct with valid attributes" do
      params = %{
        starting_price: Decimal.new("1"),
        stock_reference_price: Decimal.new("2"),
        delta: Decimal.new(".2")
      }

      assert BoxOrderParams.new(params) == %BoxOrderParams{
               starting_price: Decimal.new("1"),
               stock_reference_price: Decimal.new("2"),
               delta: Decimal.new(".2")
             }
    end
  end
end
