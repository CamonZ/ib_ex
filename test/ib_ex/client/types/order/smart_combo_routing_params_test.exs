defmodule IbEx.Client.Types.SmartComboRoutingParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    SmartComboRoutingParams
  }

  alias IbEx.Client.Types.TagValue

  describe "new/0" do
    test "creates a SmartComboRoutingParams struct with default attributes" do
      assert SmartComboRoutingParams.new() == %SmartComboRoutingParams{
               params: []
             }
    end
  end

  describe "new/1" do
    test "creates a SmartComboRoutingParams struct with valid attributes" do
      tag_value =
        TagValue.new(tag: "tag_1", value: "value_1")

      attrs = %{params: [tag_value]}

      assert SmartComboRoutingParams.new(attrs) == %SmartComboRoutingParams{
               params: [
                 tag_value
               ]
             }
    end
  end

  describe "serialize/1" do
    test "serializes SmartComboRoutingParams for Order struct, to_string == false" do
      tag_value =
        TagValue.new(tag: "tag_1", value: "value_1")

      attrs = %{params: [tag_value]}

      assert SmartComboRoutingParams.new(attrs) |> SmartComboRoutingParams.serialize() == [
               1,
               "tag_1",
               "value_1"
             ]
    end

    test "serializes SmartComboRoutingParams for Order struct, to_string == true" do
      tag_value =
        TagValue.new(tag: "tag_1", value: "value_1")

      attrs = %{params: [tag_value]}

      assert SmartComboRoutingParams.new(attrs) |> SmartComboRoutingParams.serialize(true) == [1, "tag_1=value_1"]
    end
  end
end
