defmodule IbEx.Client.Types.VolatilityOrderParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    VolatilityOrderParams
  }

  describe "new/0" do
    test "creates a VolatilityOrderParams struct with default attributes" do
      assert VolatilityOrderParams.new() == %VolatilityOrderParams{
               volatility: nil,
               volatility_type: nil
             }
    end
  end

  describe "new/1" do
    test "creates a VolatilityOrderParams struct with valid attributes" do
      attrs = %{
        volatility: Decimal.new("0.2"),
        volatility_type: 1
      }

      assert VolatilityOrderParams.new(attrs) == %VolatilityOrderParams{
               volatility: Decimal.new("0.2"),
               volatility_type: 1
             }
    end
  end

  describe "serialize/1" do
    test "serializes VolatilityOrderParams" do
      attrs = %{
        volatility: Decimal.new("0.2"),
        volatility_type: 1
      }

      params = VolatilityOrderParams.new(attrs)

      assert VolatilityOrderParams.serialize(params) == [
               attrs.volatility,
               attrs.volatility_type
             ]
    end
  end
end
