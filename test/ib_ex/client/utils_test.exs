defmodule IbEx.Client.UtilsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Utils

  # ── to_decimal ──────────────────────────────────────────────────────

  describe "to_decimal/1" do
    test "converts valid string to Decimal" do
      assert Utils.to_decimal("123.45") == Decimal.new("123.45")
    end

    test "converts float to Decimal" do
      result = Utils.to_decimal(42.5)
      assert Decimal.equal?(Decimal.round(result, 1), Decimal.new("42.5"))
    end

    test "converts integer to Decimal" do
      assert Decimal.equal?(Utils.to_decimal(42), Decimal.new("42"))
    end

    test "passes through Decimal" do
      d = Decimal.new("100.5")
      assert Utils.to_decimal(d) == d
    end

    test "returns nil for nil, empty string, and unset double string" do
      assert is_nil(Utils.to_decimal(nil))
      assert is_nil(Utils.to_decimal(""))
      assert is_nil(Utils.to_decimal("1.7976931348623157E308"))
    end
  end

  describe "to_decimal/2 with :nullable" do
    test "returns nil for nil" do
      assert Utils.to_decimal(nil, :nullable) == nil
    end

    test "returns nil for :unset_double sentinel" do
      assert Utils.to_decimal(:unset_double, :nullable) == nil
    end

    test "converts float with nullable" do
      result = Utils.to_decimal(42.5, :nullable)
      assert Decimal.equal?(Decimal.round(result, 1), Decimal.new("42.5"))
    end

    test "converts integer with nullable" do
      assert Decimal.equal?(Utils.to_decimal(42, :nullable), Decimal.new("42"))
    end
  end

  # ── to_float ────────────────────────────────────────────────────────

  describe "to_float/1" do
    test "converts valid string to float" do
      assert Utils.to_float("123.45") == 123.45
    end

    test "converts Decimal to float" do
      assert_in_delta Utils.to_float(Decimal.new("150.50")), 150.50, 0.001
    end

    test "converts integer to float" do
      assert Utils.to_float(42) == 42.0
    end

    test "passes through float" do
      assert Utils.to_float(42.5) == 42.5
    end

    test "returns nil for nil, empty string, invalid" do
      assert is_nil(Utils.to_float(nil))
      assert is_nil(Utils.to_float(""))
      assert is_nil(Utils.to_float("invalid"))
    end
  end

  describe "to_float/2 with :nullable" do
    test "returns nil for nil" do
      assert Utils.to_float(nil, :nullable) == nil
    end

    test "returns nil for :unset_double sentinel" do
      assert Utils.to_float(:unset_double, :nullable) == nil
    end

    test "converts Decimal with nullable" do
      assert_in_delta Utils.to_float(Decimal.new("42.5"), :nullable), 42.5, 0.001
    end
  end

  # ── to_integer ──────────────────────────────────────────────────────

  describe "to_integer/1" do
    test "converts valid string to integer" do
      assert Utils.to_integer("42") == 42
    end

    test "passes through integer" do
      assert Utils.to_integer(42) == 42
    end

    test "converts float to integer" do
      assert Utils.to_integer(42.6) == 43
    end

    test "returns nil for nil and empty string" do
      assert is_nil(Utils.to_integer(nil))
      assert is_nil(Utils.to_integer(""))
    end

    test "returns nil for invalid string" do
      assert is_nil(Utils.to_integer("abc"))
    end
  end

  describe "to_integer/2 with :nullable" do
    test "returns nil for nil" do
      assert Utils.to_integer(nil, :nullable) == nil
    end

    test "returns nil for :unset_integer sentinel" do
      assert Utils.to_integer(:unset_integer, :nullable) == nil
    end

    test "converts string with nullable" do
      assert Utils.to_integer("42", :nullable) == 42
    end
  end

  # ── to_string_value ─────────────────────────────────────────────────

  describe "to_string_value/1" do
    test "converts Decimal to string" do
      assert Utils.to_string_value(Decimal.new("100.5")) == "100.5"
    end

    test "converts integer to string" do
      assert Utils.to_string_value(42) == "42"
    end

    test "converts float to string" do
      assert is_binary(Utils.to_string_value(42.5))
    end

    test "converts atom to string" do
      assert Utils.to_string_value(:hello) == "hello"
    end

    test "passes through binary" do
      assert Utils.to_string_value("hello") == "hello"
    end

    test "returns nil for nil" do
      assert Utils.to_string_value(nil) == nil
    end
  end

  describe "to_string_value/2 with :nullable" do
    test "returns nil for nil" do
      assert Utils.to_string_value(nil, :nullable) == nil
    end

    test "converts value with nullable" do
      assert Utils.to_string_value(42, :nullable) == "42"
    end
  end

  # ── to_bool ─────────────────────────────────────────────────────────

  describe "to_bool/1" do
    test "converts string '1' to true and '0' to false" do
      assert Utils.to_bool("1") == true
      assert Utils.to_bool("0") == false
    end

    test "converts integer 1 to true and 0 to false" do
      assert Utils.to_bool(1) == true
      assert Utils.to_bool(0) == false
    end

    test "passes through booleans" do
      assert Utils.to_bool(true) == true
      assert Utils.to_bool(false) == false
    end

    test "non-zero integers are true" do
      assert Utils.to_bool(42) == true
      assert Utils.to_bool(-1) == true
    end

    test "handles non-numeric strings" do
      assert is_nil(Utils.to_bool("invalid"))
      assert is_nil(Utils.to_bool("123"))
      assert is_nil(Utils.to_bool("-1"))
    end
  end

  describe "to_bool/2 with :nullable" do
    test "returns nil for nil" do
      assert Utils.to_bool(nil, :nullable) == nil
    end

    test "converts value with nullable" do
      assert Utils.to_bool(1, :nullable) == true
    end
  end

  # ── boolify_mask ────────────────────────────────────────────────────

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

  # ── Timestamp parsing ──────────────────────────────────────────────

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
end
