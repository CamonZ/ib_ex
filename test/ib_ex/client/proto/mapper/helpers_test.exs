defmodule IbEx.Client.Proto.Mapper.HelpersTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Mapper.Helpers
  alias IbEx.Client.Types.TagValue

  describe "decimal_to_string/1" do
    test "converts Decimal to string" do
      assert Helpers.decimal_to_string(Decimal.new("100.5")) == "100.5"
    end

    test "returns nil for nil" do
      assert Helpers.decimal_to_string(nil) == nil
    end

    test "converts number to string" do
      assert Helpers.decimal_to_string(42) == "42"
    end
  end

  describe "string_to_decimal/1" do
    test "converts string to Decimal" do
      assert Decimal.equal?(Helpers.string_to_decimal("100.5"), Decimal.new("100.5"))
    end

    test "returns nil for nil" do
      assert Helpers.string_to_decimal(nil) == nil
    end

    test "returns nil for empty string" do
      assert Helpers.string_to_decimal("") == nil
    end
  end

  describe "decimal_to_double/1" do
    test "converts Decimal to float" do
      assert_in_delta Helpers.decimal_to_double(Decimal.new("150.50")), 150.50, 0.001
    end

    test "returns nil for nil" do
      assert Helpers.decimal_to_double(nil) == nil
    end

    test "returns nil for :unset_double" do
      assert Helpers.decimal_to_double(:unset_double) == nil
    end

    test "passes through float values" do
      assert Helpers.decimal_to_double(42.5) == 42.5
    end
  end

  describe "double_to_decimal/1" do
    test "converts float to Decimal" do
      result = Helpers.double_to_decimal(150.50)
      assert Decimal.equal?(Decimal.round(result, 2), Decimal.new("150.5"))
    end

    test "returns nil for nil" do
      assert Helpers.double_to_decimal(nil) == nil
    end

    test "converts integer to Decimal" do
      assert Decimal.equal?(Helpers.double_to_decimal(42), Decimal.new("42"))
    end
  end

  describe "unset_sentinel_to_nil/1" do
    test "converts :unset_double to nil" do
      assert Helpers.unset_sentinel_to_nil(:unset_double) == nil
    end

    test "converts :unset_integer to nil" do
      assert Helpers.unset_sentinel_to_nil(:unset_integer) == nil
    end

    test "converts :infinity to nil" do
      assert Helpers.unset_sentinel_to_nil(:infinity) == nil
    end

    test "passes through normal values" do
      assert Helpers.unset_sentinel_to_nil(42) == 42
      assert Helpers.unset_sentinel_to_nil("hello") == "hello"
    end
  end

  describe "nil_to_sentinel/2" do
    test "converts nil to specified sentinel" do
      assert Helpers.nil_to_sentinel(nil, :unset_double) == :unset_double
      assert Helpers.nil_to_sentinel(nil, :unset_integer) == :unset_integer
    end

    test "passes through non-nil values" do
      assert Helpers.nil_to_sentinel(42.0, :unset_double) == 42.0
      assert Helpers.nil_to_sentinel(10, :unset_integer) == 10
    end
  end

  describe "conid_to_int/1" do
    test "converts string conid to integer" do
      assert Helpers.conid_to_int("265598") == 265_598
    end

    test "handles '0'" do
      assert Helpers.conid_to_int("0") == 0
    end

    test "returns nil for nil" do
      assert Helpers.conid_to_int(nil) == nil
    end

    test "returns nil for empty string" do
      assert Helpers.conid_to_int("") == nil
    end

    test "passes through integer" do
      assert Helpers.conid_to_int(265_598) == 265_598
    end
  end

  describe "conid_to_string/1" do
    test "converts integer conid to string" do
      assert Helpers.conid_to_string(265_598) == "265598"
    end

    test "handles 0" do
      assert Helpers.conid_to_string(0) == "0"
    end

    test "returns nil for nil" do
      assert Helpers.conid_to_string(nil) == nil
    end
  end

  describe "strike_to_double/1 and strike_to_string/1" do
    test "converts string strike to double" do
      assert Helpers.strike_to_double("150.0") == 150.0
    end

    test "converts double strike to string" do
      assert Helpers.strike_to_string(150.0) == "150.0"
    end

    test "handles '0.0'" do
      assert Helpers.strike_to_double("0.0") == 0.0
    end

    test "handles nil" do
      assert Helpers.strike_to_double(nil) == nil
      assert Helpers.strike_to_string(nil) == nil
    end
  end

  describe "sentinel_double_to_proto/1 and proto_to_sentinel_double/1" do
    test ":unset_double becomes nil" do
      assert Helpers.sentinel_double_to_proto(:unset_double) == nil
    end

    test "nil becomes :unset_double" do
      assert Helpers.proto_to_sentinel_double(nil) == :unset_double
    end

    test "Decimal value becomes float" do
      result = Helpers.sentinel_double_to_proto(Decimal.new("42.5"))
      assert_in_delta result, 42.5, 0.001
    end

    test "float becomes Decimal" do
      result = Helpers.proto_to_sentinel_double(42.5)
      assert Decimal.equal?(Decimal.round(result, 1), Decimal.new("42.5"))
    end
  end

  describe "sentinel_int_to_proto/1 and proto_to_sentinel_int/1" do
    test ":unset_integer becomes nil" do
      assert Helpers.sentinel_int_to_proto(:unset_integer) == nil
    end

    test "nil becomes :unset_integer" do
      assert Helpers.proto_to_sentinel_int(nil) == :unset_integer
    end

    test "integer passes through" do
      assert Helpers.sentinel_int_to_proto(42) == 42
      assert Helpers.proto_to_sentinel_int(42) == 42
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

  describe "bool_to_int/1 and int_to_bool/1" do
    test "converts booleans to integers" do
      assert Helpers.bool_to_int(true) == 1
      assert Helpers.bool_to_int(false) == 0
      assert Helpers.bool_to_int(nil) == nil
    end

    test "converts integers to booleans" do
      assert Helpers.int_to_bool(1) == true
      assert Helpers.int_to_bool(0) == false
      assert Helpers.int_to_bool(nil) == nil
    end
  end
end
