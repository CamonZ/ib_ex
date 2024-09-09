defmodule IbEx.Client.Types.OrderConditionsParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.OrderCondition
  alias IbEx.Client.Types.Order.OrderConditionsParams

  describe "new/0" do
    test "creates a OrderConditionsParams struct with default attributes" do
      assert OrderConditionsParams.new() == %OrderConditionsParams{
               conditions: [],
               conditions_cancel_order: false,
               conditions_ignore_rth: false
             }
    end
  end

  describe "new/1" do
    test "creates a OrderConditionsParams struct with valid attributes" do
      params = %{
        conditions: [],
        conditions_cancel_order: true,
        conditions_ignore_rth: true
      }

      assert OrderConditionsParams.new(params) == %OrderConditionsParams{
               conditions: [],
               conditions_cancel_order: true,
               conditions_ignore_rth: true
             }
    end
  end

  describe "serialize/1" do
    test "serializes for conditions == []" do
      params = %{
        conditions: [],
        conditions_cancel_order: true,
        conditions_ignore_rth: true
      }

      assert OrderConditionsParams.new(params) |> OrderConditionsParams.serialize() == [0]
    end

    test "serializes for conditions != []" do
      params = %{
        conditions: [OrderCondition.new()],
        conditions_cancel_order: true,
        conditions_ignore_rth: true
      }

      assert OrderConditionsParams.new(params) |> OrderConditionsParams.serialize() == [1, true, true]
    end
  end
end
