defmodule IbEx.Client.Types.PegToBenchmarkOrderParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.PegToBenchmarkOrderParams

  describe "new/0" do
    test "creates a PegToBenchmarkOrderParams struct with default attributes" do
      assert PegToBenchmarkOrderParams.new() == %PegToBenchmarkOrderParams{
               reference_contract_id: 0,
               is_pegged_change_amount_decrease: false,
               pegged_change_amount: Decimal.new("0.0"),
               reference_change_amoung: Decimal.new("0.0"),
               reference_exchange_id: nil
             }
    end
  end

  describe "new/1" do
    test "creates a PegToBenchmarkOrderParams struct with valid attributes" do
      params = %{
        reference_contract_id: 1,
        is_pegged_change_amount_decrease: true,
        pegged_change_amount: Decimal.new("1.0"),
        reference_change_amoung: Decimal.new("2.0"),
        reference_exchange_id: "reference_exchange_id"
      }

      assert PegToBenchmarkOrderParams.new(params) == %PegToBenchmarkOrderParams{
               reference_contract_id: 1,
               is_pegged_change_amount_decrease: true,
               pegged_change_amount: Decimal.new("1.0"),
               reference_change_amoung: Decimal.new("2.0"),
               reference_exchange_id: "reference_exchange_id"
             }
    end
  end

  describe "serialize/1" do
    test "serializes for PEG BENCH order types" do
      params = %{
        reference_contract_id: 1,
        is_pegged_change_amount_decrease: true,
        pegged_change_amount: Decimal.new("1.0"),
        reference_change_amoung: Decimal.new("2.0"),
        reference_exchange_id: "reference_exchange_id"
      }

      assert PegToBenchmarkOrderParams.new(params) |> PegToBenchmarkOrderParams.serialize(true) == [
               params.reference_contract_id,
               params.is_pegged_change_amount_decrease,
               params.pegged_change_amount,
               params.reference_change_amoung,
               params.reference_exchange_id
             ]
    end

    test "serializes for non PEG BENCH order types" do
      params = %{
        reference_contract_id: 1,
        is_pegged_change_amount_decrease: true,
        pegged_change_amount: Decimal.new("1.0"),
        reference_change_amoung: Decimal.new("2.0"),
        reference_exchange_id: "reference_exchange_id"
      }

      assert PegToBenchmarkOrderParams.new(params) |> PegToBenchmarkOrderParams.serialize(false) == []
    end
  end
end
