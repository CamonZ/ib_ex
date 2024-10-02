defmodule IbEx.Client.Types.DeltaNeutralParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    DeltaNeutralParams
  }

  describe "new/0" do
    test "creates a DeltaNeutralParams struct with default attributes" do
      assert DeltaNeutralParams.new() == %DeltaNeutralParams{
               order_type: nil,
               aux_price: nil,
               conid: 0,
               settling_firm: nil,
               clearing_account: nil,
               clearing_intent: nil,
               open_close: nil,
               short_sale: false,
               short_sale_slot: 0,
               designated_location: nil
             }
    end
  end

  describe "new/1" do
    test "creates a DeltaNeutralParams struct with valid attributes" do
      attrs = %{
        order_type: "LMT",
        aux_price: Decimal.new("123"),
        conid: 2,
        settling_firm: "settling_firm",
        clearing_account: "clearing_account",
        clearing_intent: "clearing_intent",
        open_close: "open_close",
        short_sale: true,
        short_sale_slot: 1,
        designated_location: "designated_location"
      }

      assert DeltaNeutralParams.new(attrs) == %DeltaNeutralParams{
               order_type: "LMT",
               aux_price: Decimal.new("123"),
               conid: 2,
               settling_firm: "settling_firm",
               clearing_account: "clearing_account",
               clearing_intent: "clearing_intent",
               open_close: "open_close",
               short_sale: true,
               short_sale_slot: 1,
               designated_location: "designated_location"
             }
    end
  end

  describe "serialize/1" do
    test "serializes DeltaNeutralParams when order_type is present and not empty " do
      attrs = %{
        order_type: "LMT",
        aux_price: Decimal.new("123"),
        conid: 2,
        settling_firm: "settling_firm",
        clearing_account: "clearing_account",
        clearing_intent: "clearing_intent",
        open_close: "open_close",
        short_sale: true,
        short_sale_slot: 1,
        designated_location: "designated_location"
      }

      params = DeltaNeutralParams.new(attrs)

      assert DeltaNeutralParams.serialize(params) == [
               attrs.order_type,
               attrs.aux_price,
               attrs.conid,
               attrs.settling_firm,
               attrs.clearing_account,
               attrs.clearing_intent,
               attrs.open_close,
               attrs.short_sale,
               attrs.short_sale_slot,
               attrs.designated_location
             ]
    end
  end
end
