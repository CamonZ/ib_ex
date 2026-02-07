defmodule IbEx.Client.Proto.Mapper.HelpersTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Mapper.Helpers
  alias IbEx.Client.Types.TagValue

  describe "maybe_unset_double/1" do
    test "returns nil for nil" do
      assert Helpers.maybe_unset_double(nil) == nil
    end

    test "converts unset double sentinel to :unset_double" do
      assert Helpers.maybe_unset_double(1.7976931348623157e308) == :unset_double
    end

    test "passes through normal float" do
      assert Helpers.maybe_unset_double(42.5) == 42.5
    end
  end

  describe "maybe_unset_integer/1" do
    test "returns nil for nil" do
      assert Helpers.maybe_unset_integer(nil) == nil
    end

    test "converts unset integer sentinel to :unset_integer" do
      assert Helpers.maybe_unset_integer(2_147_483_647) == :unset_integer
    end

    test "passes through normal integer" do
      assert Helpers.maybe_unset_integer(42) == 42
    end
  end

  describe "tag_value_list_to_map/1" do
    test "converts TagValue list to map" do
      list = [
        %TagValue{tag: "key1", value: "val1"},
        %TagValue{tag: "key2", value: "val2"}
      ]

      result = Helpers.tag_value_list_to_map(list)
      assert result == %{"key1" => "val1", "key2" => "val2"}
    end

    test "returns empty map for nil" do
      assert Helpers.tag_value_list_to_map(nil) == %{}
    end

    test "returns empty map for empty list" do
      assert Helpers.tag_value_list_to_map([]) == %{}
    end
  end

  describe "map_to_tag_value_list/1" do
    test "converts map to TagValue list" do
      result = Helpers.map_to_tag_value_list(%{"key1" => "val1", "key2" => "val2"})
      assert length(result) == 2

      tags = Enum.map(result, & &1.tag) |> Enum.sort()
      assert tags == ["key1", "key2"]

      values = Enum.map(result, & &1.value) |> Enum.sort()
      assert values == ["val1", "val2"]
    end

    test "returns empty list for nil" do
      assert Helpers.map_to_tag_value_list(nil) == []
    end

    test "returns empty list for empty map" do
      assert Helpers.map_to_tag_value_list(%{}) == []
    end
  end
end
