defmodule IbEx.Client.Types.TagValueListTest do
  use ExUnit.Case, async: true
  alias IbEx.Client.Types.{TagValue, TagValueList}

  describe "serialize/1" do
    test "serializes an empty list" do
      assert TagValueList.serialize([]) == []
    end

    test "serializes a list of TagValue structs" do
      params = [
        TagValue.new(%{
          tag: "tag_1",
          value: "value_1"
        }),
        TagValue.new(%{
          tag: "tag_2",
          value: "value_2"
        })
      ]

      assert TagValueList.serialize(params) == [
               "tag_1",
               "value_1",
               "tag_2",
               "value_2"
             ]
    end
  end

  describe "serialize_to_string/1" do
    test "serializes an empty list into a string" do
      assert TagValueList.serialize_to_string([]) == ""
    end

    test "serializes a list of TagValue structs into a string" do
      params = [
        TagValue.new(%{
          tag: "tag_1",
          value: "value_1"
        }),
        TagValue.new(%{
          tag: "tag_2",
          value: "value_2"
        })
      ]

      assert TagValueList.serialize_to_string(params) == "tag_1=value_1,tag_2=value_2"
    end
  end
end
