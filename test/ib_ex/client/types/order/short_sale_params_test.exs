defmodule IbEx.Client.Types.ShortSaleParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    ShortSaleParams
  }

  describe "new/0" do
    test "creates a ShortSaleParams struct with default attributes" do
      assert ShortSaleParams.new() == %ShortSaleParams{
               short_sale_slot: 0,
               designated_location: nil,
               exempt_code: -1
             }
    end
  end

  describe "new/1" do
    test "creates a ShortSaleParams struct with valid attributes" do
      params = %{
        short_sale_slot: 2,
        designated_location: "location",
        exempt_code: -1
      }

      assert ShortSaleParams.new(params) == %ShortSaleParams{
               short_sale_slot: 2,
               designated_location: "location",
               exempt_code: -1
             }
    end

    test "does not populate designated_location when short_sale_slot != 2" do
      assert ShortSaleParams.new(%{
               short_sale_slot: 1,
               designated_location: "location",
               exempt_code: -1
             }) == %ShortSaleParams{
               short_sale_slot: 1,
               designated_location: nil,
               exempt_code: -1
             }

      assert ShortSaleParams.new(%{
               short_sale_slot: 0,
               designated_location: "location",
               exempt_code: -1
             }) == %ShortSaleParams{
               short_sale_slot: 0,
               designated_location: nil,
               exempt_code: -1
             }
    end
  end

  describe "serialize/1" do
    test "serializes ShortSaleParams" do
      params = %{
        short_sale_slot: 2,
        designated_location: "location",
        exempt_code: -1
      }

      assert ShortSaleParams.new(params) |> ShortSaleParams.serialize() == [
               params.short_sale_slot,
               params.designated_location,
               params.exempt_code
             ]
    end
  end
end
