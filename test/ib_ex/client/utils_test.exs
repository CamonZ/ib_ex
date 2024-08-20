defmodule IbEx.Client.UtilsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Utils

  describe "boolify_mask/2" do
    test "returns true if the flag bit is set in the mask" do
      assert Utils.boolify_mask(0b0101, 0b0001) == true
      assert Utils.boolify_mask(0b1100, 0b0100) == true
    end

    test "returns false if the flag bit is not set in the mask" do
      assert Utils.boolify_mask(0b0100, 0b0001) == false
      assert Utils.boolify_mask(0b0010, 0b1000) == false
    end

    test "works with different mask and flag bit combinations" do
      assert Utils.boolify_mask(0b1111, 0b0001) == true
      assert Utils.boolify_mask(0b0000, 0b0000) == false
      assert Utils.boolify_mask(0b1010, 0b1000) == true
      assert Utils.boolify_mask(0b0101, 0b1000) == false
    end

    test "handles binary inputs" do
      assert Utils.boolify_mask("15", "2") == true
      assert Utils.boolify_mask("5", 2) == false
      assert Utils.boolify_mask(5, "1") == true
    end
  end

  describe "parse_timestamp_str/1" do
    test "parses valid timestamp string correctly" do
      assert {:ok, ts} = Utils.parse_timestamp_str("20231204 22:39:34 Europe/Madrid")
      assert ts == ~U[2023-12-04 21:39:34Z]
    end

    test "handles invalid timestamp string" do
      assert {:error, :invalid_args} == Utils.parse_timestamp_str("")
    end

    test "handles other types of args" do
      assert {:error, :invalid_args} == Utils.parse_timestamp_str(nil)
    end

    test "handles timestamp string with incorrect format" do
      assert {:error, :invalid_args} == Utils.parse_timestamp_str("2023-12-05 15:30:00")
    end
  end

  describe "to_decimal/1" do
    test "converts valid string to Decimal" do
      assert Utils.to_decimal("123.45") == Decimal.new("123.45")
    end

    test "returns nil for invalid or special inputs" do
      assert is_nil(Utils.to_decimal(nil))
      assert is_nil(Utils.to_decimal(""))
      assert is_nil(Utils.to_decimal("1.7976931348623157E308"))
    end
  end

  describe "to_float/1" do
    test "converts valid string to float" do
      assert Utils.to_float("123.45") == 123.45
    end

    test "returns nil for invalid inputs" do
      assert is_nil(Utils.to_float(nil))
      assert is_nil(Utils.to_float(""))
      assert is_nil(Utils.to_float("invalid"))
    end
  end

  describe "to_bool/1" do
    test "converts string '1' to true and '0' to false" do
      assert Utils.to_bool("1") == true
      assert Utils.to_bool("0") == false
    end

    test "handles non-numeric strings" do
      assert is_nil(Utils.to_bool("invalid"))
      assert is_nil(Utils.to_bool("123"))
      assert is_nil(Utils.to_bool("-1"))
    end
  end

  describe "bool_to_int/1" do
    test "converts false to 0 and true to 1" do
      assert Utils.bool_to_int(false) == {:ok, 0}
      assert Utils.bool_to_int(true) == {:ok, 1}
    end

    test "returns :invalid_args for bad arguments" do
      assert Utils.bool_to_int(:not_a_bool) == {:error, :invalid_args}
    end
  end
end
