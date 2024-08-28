defmodule IbEx.Client.Types.VolatilityOrderParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    VolatilityOrderParams
  }

  describe "new/0" do
    test "creates a VolatilityOrderParams struct with default attributes" do
      assert VolatilityOrderParams.new() == %VolatilityOrderParams{
               volatility: nil,
               volatility_type: nil,
               delta_neutral_order_type: nil,
               delta_neutral_aux_price: nil,
               delta_neutral_conid: 0,
               delta_neutral_settling_firm: nil,
               delta_neutral_clearing_account: nil,
               delta_neutral_clearing_intent: nil,
               delta_neutral_open_close: nil,
               delta_neutral_short_sale: false,
               delta_neutral_short_sale_slot: 0,
               delta_neutral_designated_location: nil
             }
    end
  end

  describe "new/1" do
    test "creates a VolatilityOrderParams struct with valid attributes" do
      attrs = %{
        volatility: Decimal.new("0.2"),
        volatility_type: 1,
        delta_neutral_order_type: "LMT",
        delta_neutral_aux_price: Decimal.new("123"),
        delta_neutral_conid: 2,
        delta_neutral_settling_firm: "settling_firm",
        delta_neutral_clearing_account: "clearing_account",
        delta_neutral_clearing_intent: "clearing_intent",
        delta_neutral_open_close: "open_close",
        delta_neutral_short_sale: true,
        delta_neutral_short_sale_slot: 1,
        delta_neutral_designated_location: "designated_location"
      }

      assert VolatilityOrderParams.new(attrs) == %VolatilityOrderParams{
               volatility: Decimal.new("0.2"),
               volatility_type: 1,
               delta_neutral_order_type: "LMT",
               delta_neutral_aux_price: Decimal.new("123"),
               delta_neutral_conid: 2,
               delta_neutral_settling_firm: "settling_firm",
               delta_neutral_clearing_account: "clearing_account",
               delta_neutral_clearing_intent: "clearing_intent",
               delta_neutral_open_close: "open_close",
               delta_neutral_short_sale: true,
               delta_neutral_short_sale_slot: 1,
               delta_neutral_designated_location: "designated_location"
             }
    end
  end

  describe "serialize/1" do
    test "serializes VolatilityOrderParams when volatility_type is present and valid" do
      attrs = %{
        volatility: Decimal.new("0.2"),
        volatility_type: 1,
        delta_neutral_order_type: "LMT",
        delta_neutral_aux_price: Decimal.new("123"),
        delta_neutral_conid: 2,
        delta_neutral_settling_firm: "settling_firm",
        delta_neutral_clearing_account: "clearing_account",
        delta_neutral_clearing_intent: "clearing_intent",
        delta_neutral_open_close: "open_close",
        delta_neutral_short_sale: true,
        delta_neutral_short_sale_slot: 1,
        delta_neutral_designated_location: "designated_location"
      }

      params = VolatilityOrderParams.new(attrs)

      assert VolatilityOrderParams.serialize(params) == [
               attrs.volatility,
               attrs.volatility_type,
               attrs.delta_neutral_order_type,
               attrs.delta_neutral_aux_price,
               attrs.delta_neutral_conid,
               attrs.delta_neutral_settling_firm,
               attrs.delta_neutral_clearing_account,
               attrs.delta_neutral_clearing_intent,
               attrs.delta_neutral_open_close,
               attrs.delta_neutral_short_sale,
               attrs.delta_neutral_short_sale_slot,
               attrs.delta_neutral_designated_location
             ]
    end
  end
end
