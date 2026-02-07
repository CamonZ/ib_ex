defmodule IbEx.Client.Utils do
  @moduledoc """
  Common utils used when casting data into different types.

  Provides unified `to_TYPE` conversion functions that accept multiple input types.
  Each function has a 1-arity form (expects valid input) and a 2-arity form with
  `:nullable` that returns nil for nil and sentinel atoms (`:unset_double`, `:unset_integer`).
  """

  @unset_double "1.7976931348623157E308"
  @timestamp_regex ~r/(\d{6})\s{1}(\d{2}\:\d{2}:\d{2})\s{1}(.*)/

  # ── to_decimal ──────────────────────────────────────────────────────

  @doc """
  Converts a value to Decimal.

  Accepts: float, integer, string, Decimal (passthrough).

  The 1-arity form handles nil, empty string, and the IB unset-double string
  sentinel by returning nil (for backward compatibility with the old wire-protocol
  callers).

  With `:nullable`, nil and sentinel atoms return nil.
  """
  @spec to_decimal(String.t() | number() | Decimal.t() | nil) :: Decimal.t() | nil
  def to_decimal(nil), do: nil
  def to_decimal(@unset_double), do: nil
  def to_decimal(""), do: nil
  def to_decimal(%Decimal{} = d), do: d
  def to_decimal(val) when is_float(val), do: Decimal.from_float(val)
  def to_decimal(val) when is_integer(val), do: Decimal.new(val)
  def to_decimal(val) when is_binary(val), do: Decimal.new(val)

  @spec to_decimal(any(), :nullable) :: Decimal.t() | nil
  def to_decimal(nil, :nullable), do: nil
  def to_decimal(:unset_double, :nullable), do: nil
  def to_decimal(val, :nullable), do: to_decimal(val)

  # ── to_float ────────────────────────────────────────────────────────

  @doc """
  Converts a value to float.

  Accepts: Decimal, string, integer, float (passthrough).
  Returns nil for nil, empty string, or unparseable strings.

  With `:nullable`, nil and sentinel atoms (`:unset_double`) return nil.
  """
  @spec to_float(String.t() | number() | Decimal.t() | nil) :: float() | nil
  def to_float(nil), do: nil
  def to_float(""), do: nil
  def to_float(%Decimal{} = d), do: Decimal.to_float(d)
  def to_float(val) when is_float(val), do: val
  def to_float(val) when is_integer(val), do: val / 1

  def to_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error -> nil
    end
  end

  @spec to_float(any(), :nullable) :: float() | nil
  def to_float(nil, :nullable), do: nil
  def to_float(:unset_double, :nullable), do: nil
  def to_float(val, :nullable), do: to_float(val)

  # ── to_integer ──────────────────────────────────────────────────────

  @doc """
  Converts a value to integer.

  Accepts: string, float, integer (passthrough).
  Returns nil for nil or empty string.

  With `:nullable`, nil and sentinel atoms (`:unset_integer`) return nil.
  """
  @spec to_integer(String.t() | number() | nil) :: integer() | nil
  def to_integer(nil), do: nil
  def to_integer(""), do: nil
  def to_integer(val) when is_integer(val), do: val
  def to_integer(val) when is_float(val), do: round(val)

  def to_integer(val) when is_binary(val) do
    String.to_integer(val)
  rescue
    _ -> nil
  end

  @spec to_integer(any(), :nullable) :: integer() | nil
  def to_integer(nil, :nullable), do: nil
  def to_integer(:unset_integer, :nullable), do: nil
  def to_integer(val, :nullable), do: to_integer(val)

  # ── to_string_value ─────────────────────────────────────────────────

  @doc """
  Converts a value to string.

  Named `to_string_value` to avoid conflict with `Kernel.to_string/1`.
  Accepts: Decimal, integer, float, atom, binary (passthrough).
  Returns nil for nil.

  With `:nullable`, nil returns nil.
  """
  @spec to_string_value(Decimal.t() | number() | atom() | String.t() | nil) :: String.t() | nil
  def to_string_value(nil), do: nil
  def to_string_value(%Decimal{} = d), do: Decimal.to_string(d, :normal)
  def to_string_value(val) when is_integer(val), do: Integer.to_string(val)
  def to_string_value(val) when is_float(val), do: Float.to_string(val)
  def to_string_value(val) when is_atom(val), do: Atom.to_string(val)
  def to_string_value(val) when is_binary(val), do: val

  @spec to_string_value(any(), :nullable) :: String.t() | nil
  def to_string_value(nil, :nullable), do: nil
  def to_string_value(val, :nullable), do: to_string_value(val)

  # ── to_bool ─────────────────────────────────────────────────────────

  @doc """
  Converts a value to boolean.

  Accepts: integer (0/1), string ("0"/"1"), boolean (passthrough).
  Returns nil for unrecognized values.

  With `:nullable`, nil returns nil.
  """
  @spec to_bool(integer() | String.t() | boolean() | nil) :: boolean() | nil
  def to_bool(true), do: true
  def to_bool(false), do: false
  def to_bool(1), do: true
  def to_bool(0), do: false
  def to_bool("1"), do: true
  def to_bool("0"), do: false
  def to_bool(val) when is_integer(val), do: val != 0
  def to_bool(_), do: nil

  @spec to_bool(any(), :nullable) :: boolean() | nil
  def to_bool(nil, :nullable), do: nil
  def to_bool(val, :nullable), do: to_bool(val)

  # ── boolify_mask ────────────────────────────────────────────────────

  def boolify_mask(mask, flag_bit) when is_integer(mask) and is_integer(flag_bit) do
    Bitwise.band(mask, flag_bit) != 0
  end

  def boolify_mask(mask, flag_bit) when is_binary(mask) do
    boolify_mask(String.to_integer(mask), flag_bit)
  end

  def boolify_mask(mask, flag_bit) when is_binary(flag_bit) do
    boolify_mask(mask, String.to_integer(flag_bit))
  end

  # ── Timestamp parsing ──────────────────────────────────────────────

  def parse_init_connection_timestamp(str) when is_binary(str) do
    case Regex.run(@timestamp_regex, str) do
      [_, date, time, _timezone] ->
        parse_timestamp_str("#{date} #{time}", "%y%m%d %H:%M:%S", false)

      _ ->
        {:error, :unknown_timezone}
    end
  end

  def parse_timestamp_str(str, formatter \\ "%Y%m%d %H:%M:%S %Z", convert_to_utc? \\ true)

  def parse_timestamp_str(str, formatter, convert_to_utc?) when is_binary(str) do
    {:ok, ts} = Timex.parse(str, formatter, :strftime)

    if convert_to_utc? do
      {:ok, Timex.Timezone.convert(ts, "Etc/UTC")}
    else
      {:ok, ts}
    end
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def parse_timestamp_str(_, _, _) do
    {:error, :invalid_args}
  end

  # ── list_to_union_type ─────────────────────────────────────────────

  @spec list_to_union_type(list(atom)) :: String.t()
  def list_to_union_type(value) when is_list(value) do
    Enum.reduce(value, &{:|, [], [&1, &2]})
  end
end
