defmodule IbEx.Client.Proto.Mapper.Helpers do
  @moduledoc """
  Shared helper functions for converting between IbEx domain types and proto structs.

  Handles Decimal <-> double/string, sentinel values, and nil translation.
  """

  @unset_double_value 1.7976931348623157e308
  @unset_integer_value 2_147_483_647

  @doc """
  Converts a Decimal value to a string suitable for proto string fields (e.g., totalQuantity).
  Returns nil when given nil.
  """
  @spec decimal_to_string(Decimal.t() | nil) :: String.t() | nil
  def decimal_to_string(nil), do: nil
  def decimal_to_string(%Decimal{} = d), do: Decimal.to_string(d, :normal)
  def decimal_to_string(val) when is_number(val), do: to_string(val)

  @doc """
  Converts a string to a Decimal. Returns nil when given nil or empty string.
  """
  @spec string_to_decimal(String.t() | nil) :: Decimal.t() | nil
  def string_to_decimal(nil), do: nil
  def string_to_decimal(""), do: nil
  def string_to_decimal(str) when is_binary(str), do: Decimal.new(str)

  @doc """
  Converts a Decimal to a float for proto double fields.
  Returns nil when given nil or sentinel values.
  """
  @spec decimal_to_double(Decimal.t() | number() | nil | :unset_double) :: float() | nil
  def decimal_to_double(nil), do: nil
  def decimal_to_double(:unset_double), do: nil
  def decimal_to_double(%Decimal{} = d), do: Decimal.to_float(d)
  def decimal_to_double(val) when is_float(val), do: val
  def decimal_to_double(val) when is_integer(val), do: val / 1

  @doc """
  Converts a proto double to a Decimal. Returns nil when given nil.
  """
  @spec double_to_decimal(float() | nil) :: Decimal.t() | nil
  def double_to_decimal(nil), do: nil
  def double_to_decimal(val) when is_float(val), do: Decimal.from_float(val)
  def double_to_decimal(val) when is_integer(val), do: Decimal.new(val)

  @doc """
  Converts an IbEx sentinel value (:unset_double, :unset_integer) to nil for proto.
  Non-sentinel values pass through unchanged.
  """
  @spec unset_sentinel_to_nil(any()) :: any()
  def unset_sentinel_to_nil(:unset_double), do: nil
  def unset_sentinel_to_nil(:unset_integer), do: nil
  def unset_sentinel_to_nil(:infinity), do: nil
  def unset_sentinel_to_nil(val), do: val

  @doc """
  Converts a nil proto value back to the appropriate IbEx sentinel.

  ## Examples

      iex> nil_to_sentinel(nil, :unset_double)
      :unset_double

      iex> nil_to_sentinel(42.0, :unset_double)
      42.0
  """
  @spec nil_to_sentinel(any(), atom()) :: any()
  def nil_to_sentinel(nil, sentinel), do: sentinel
  def nil_to_sentinel(val, _sentinel), do: val

  @doc """
  Converts a string conid (domain) to an integer (proto).
  """
  @spec conid_to_int(String.t() | nil) :: integer() | nil
  def conid_to_int(nil), do: nil
  def conid_to_int("0"), do: 0
  def conid_to_int(""), do: nil
  def conid_to_int(str) when is_binary(str), do: String.to_integer(str)
  def conid_to_int(val) when is_integer(val), do: val

  @doc """
  Converts an integer conid (proto) to a string (domain).
  """
  @spec conid_to_string(integer() | nil) :: String.t() | nil
  def conid_to_string(nil), do: nil
  def conid_to_string(0), do: "0"
  def conid_to_string(val) when is_integer(val), do: Integer.to_string(val)

  @doc """
  Converts a string strike price (domain) to a double (proto).
  """
  @spec strike_to_double(String.t() | nil) :: float() | nil
  def strike_to_double(nil), do: nil
  def strike_to_double("0.0"), do: 0.0
  def strike_to_double(""), do: nil

  def strike_to_double(str) when is_binary(str) do
    {val, _} = Float.parse(str)
    val
  end

  @doc """
  Converts a proto double strike to a string (domain).
  """
  @spec strike_to_string(float() | nil) :: String.t() | nil
  def strike_to_string(nil), do: nil
  def strike_to_string(val) when is_float(val), do: Float.to_string(val)
  def strike_to_string(val) when is_integer(val), do: Float.to_string(val / 1)

  @doc """
  Converts a boolean to an integer (0 or 1) for proto int32 fields that represent booleans.
  """
  @spec bool_to_int(boolean() | nil) :: integer() | nil
  def bool_to_int(nil), do: nil
  def bool_to_int(true), do: 1
  def bool_to_int(false), do: 0

  @doc """
  Converts an integer (0 or 1) to a boolean.
  """
  @spec int_to_bool(integer() | nil) :: boolean() | nil
  def int_to_bool(nil), do: nil
  def int_to_bool(0), do: false
  def int_to_bool(1), do: true
  def int_to_bool(val) when is_integer(val), do: val != 0

  @doc """
  Converts an IbEx sentinel double value to nil for proto, or a Decimal/float to double.
  Combines unset_sentinel_to_nil with decimal_to_double.
  """
  @spec sentinel_double_to_proto(any()) :: float() | nil
  def sentinel_double_to_proto(:unset_double), do: nil
  def sentinel_double_to_proto(%Decimal{} = d), do: Decimal.to_float(d)
  def sentinel_double_to_proto(nil), do: nil
  def sentinel_double_to_proto(val) when is_float(val), do: val
  def sentinel_double_to_proto(val) when is_integer(val), do: val / 1

  @doc """
  Converts a proto double to an IbEx value, using :unset_double sentinel for nil.
  """
  @spec proto_to_sentinel_double(float() | nil) :: Decimal.t() | :unset_double
  def proto_to_sentinel_double(nil), do: :unset_double
  def proto_to_sentinel_double(val) when is_float(val), do: Decimal.from_float(val)
  def proto_to_sentinel_double(val) when is_integer(val), do: Decimal.new(val)

  @doc """
  Converts an IbEx sentinel integer value to nil for proto.
  """
  @spec sentinel_int_to_proto(any()) :: integer() | nil
  def sentinel_int_to_proto(:unset_integer), do: nil
  def sentinel_int_to_proto(nil), do: nil
  def sentinel_int_to_proto(val) when is_integer(val), do: val

  @doc """
  Converts a proto integer to an IbEx value, using :unset_integer sentinel for nil.
  """
  @spec proto_to_sentinel_int(integer() | nil) :: integer() | :unset_integer
  def proto_to_sentinel_int(nil), do: :unset_integer
  def proto_to_sentinel_int(val) when is_integer(val), do: val

  @doc """
  Converts a proto double that represents the IB unset double sentinel back to the atom.
  This checks for the actual unset value (1.7976931348623157E308).
  """
  @spec maybe_unset_double(float() | nil) :: :unset_double | float() | nil
  def maybe_unset_double(nil), do: nil
  def maybe_unset_double(val) when val == @unset_double_value, do: :unset_double
  def maybe_unset_double(val), do: val

  @doc """
  Converts a proto int that represents the IB unset integer sentinel back to the atom.
  """
  @spec maybe_unset_integer(integer() | nil) :: :unset_integer | integer() | nil
  def maybe_unset_integer(nil), do: nil
  def maybe_unset_integer(@unset_integer_value), do: :unset_integer
  def maybe_unset_integer(val), do: val

  @doc """
  Converts a TagValue list to a proto map (map<string, string>).
  """
  @spec tag_value_list_to_map(list() | nil) :: map()
  def tag_value_list_to_map(nil), do: %{}
  def tag_value_list_to_map([]), do: %{}

  def tag_value_list_to_map(list) when is_list(list) do
    Enum.reduce(list, %{}, fn %{tag: tag, value: value}, acc ->
      Map.put(acc, tag || "", value || "")
    end)
  end

  @doc """
  Converts a proto map (map<string, string>) to a TagValue list.
  """
  @spec map_to_tag_value_list(map() | nil) :: list()
  def map_to_tag_value_list(nil), do: []
  def map_to_tag_value_list(map) when map == %{}, do: []

  def map_to_tag_value_list(map) when is_map(map) do
    alias IbEx.Client.Types.TagValue

    Enum.map(map, fn {key, value} ->
      %TagValue{tag: key, value: value}
    end)
  end

  @doc """
  Converts an integer to boolean or nil. For proto int32 fields like route_marketable_to_bbo
  that the domain treats as boolean.
  """
  @spec int_to_bool_or_value(integer() | nil) :: boolean() | nil
  def int_to_bool_or_value(nil), do: nil
  def int_to_bool_or_value(val) when is_integer(val), do: val != 0

  @doc """
  Converts a boolean domain value to int for proto fields that use int32 for bool semantics.
  """
  @spec bool_or_value_to_int(boolean() | nil) :: integer() | nil
  def bool_or_value_to_int(nil), do: nil
  def bool_or_value_to_int(true), do: 1
  def bool_or_value_to_int(false), do: 0
  def bool_or_value_to_int(val) when is_integer(val), do: val
end
