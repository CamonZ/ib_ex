defmodule IbEx.Client.Types.ClearingInfoParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.ClearingInfoParams

  describe "new/0" do
    test "creates a ClearingInfoParams struct with default attributes" do
      assert ClearingInfoParams.new() == %ClearingInfoParams{
               account: nil,
               settling_firm: nil,
               clearing_account: nil,
               clearing_intent: nil
             }
    end
  end

  describe "new/1" do
    test "creates a ClearingInfoParams struct with valid attributes" do
      params = %{
        account: "account",
        settling_firm: "settling_firm",
        clearing_account: "clearing_account",
        clearing_intent: "IB"
      }

      assert ClearingInfoParams.new(params) == %ClearingInfoParams{
               account: "account",
               settling_firm: "settling_firm",
               clearing_account: "clearing_account",
               clearing_intent: "IB"
             }
    end
  end

  describe "serialize/1" do
    test "serializes ClearingInfoParams" do
      params = %{
        account: "account",
        settling_firm: "settling_firm",
        clearing_account: "clearing_account",
        clearing_intent: "IB"
      }

      assert ClearingInfoParams.new(params) |> ClearingInfoParams.serialize() == [
               params.clearing_account,
               params.clearing_intent
             ]
    end
  end
end
