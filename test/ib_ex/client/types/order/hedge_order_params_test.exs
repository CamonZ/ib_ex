defmodule IbEx.Client.Types.HedgeOrderParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    HedgeOrderParams
  }

  describe "new/0" do
    test "creates a HedgeOrderParams struct with default attributes" do
      assert HedgeOrderParams.new() == %HedgeOrderParams{
               hedge_type: nil,
               hedge_param: nil
             }
    end
  end

  describe "new/1" do
    test "creates a HedgeOrderParams struct with valid attributes" do
      attrs = %{
        hedge_type: "D",
        hedge_param: "key=value"
      }

      assert HedgeOrderParams.new(attrs) == %HedgeOrderParams{
               hedge_type: "D",
               hedge_param: "key=value"
             }
    end
  end

  describe "serialize/1" do
    test "serializes with hedge_type == nil" do
      params = %{
        hedge_type: nil,
        hedge_param: "key=value"
      }

      assert HedgeOrderParams.new(params) |> HedgeOrderParams.serialize() == [
               params.hedge_type
             ]
    end

    test "serializes with hedge_type != nil" do
      params = %{
        hedge_type: "D",
        hedge_param: "key=value"
      }

      assert HedgeOrderParams.new(params) |> HedgeOrderParams.serialize() == [
               params.hedge_type,
               params.hedge_param
             ]
    end
  end
end
