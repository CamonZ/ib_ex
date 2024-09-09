defmodule IbEx.Client.Types.SoftDollarTierParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.SoftDollarTierParams

  describe "new/0" do
    test "creates a SoftDollarTierParams struct with default attributes" do
      assert SoftDollarTierParams.new() == %SoftDollarTierParams{
               name: nil,
               value: nil,
               display_name: nil
             }
    end
  end

  describe "new/1" do
    test "creates a SoftDollarTierParams struct with valid attributes" do
      params = %{
        name: "name",
        value: Decimal.new("123"),
        display_name: "display_name"
      }

      assert SoftDollarTierParams.new(params) == %SoftDollarTierParams{
               name: "name",
               value: Decimal.new("123"),
               display_name: "display_name"
             }
    end
  end

  describe "serialize/1" do
    test "serializes SoftDollarTierParams" do
      params = %{
        name: "name",
        value: Decimal.new("123"),
        display_name: "display_name"
      }

      assert SoftDollarTierParams.new(params) |> SoftDollarTierParams.serialize() == [
               params.name,
               params.value
             ]
    end
  end
end
