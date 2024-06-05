defmodule IbEx.Client.Utils do
  @moduledoc """
    Common utils used when casting data into different types
  """

  @unset_double "1.7976931348623157E308"

  @timezone_names_to_zone_id %{
    "Central European Standard Time" => "CET"
  }

  @timestamp_regex ~r/(\d{6})\s{1}(\d{2}\:\d{2}:\d{2})\s{1}(.*)/

  def boolify_mask(mask, flag_bit) when is_integer(mask) and is_integer(flag_bit) do
    Bitwise.band(mask, flag_bit) != 0
  end

  def boolify_mask(mask, flag_bit) when is_binary(mask) do
    boolify_mask(String.to_integer(mask), flag_bit)
  end

  def boolify_mask(mask, flag_bit) when is_binary(flag_bit) do
    boolify_mask(mask, String.to_integer(flag_bit))
  end

  def to_decimal(str) do
    case str do
      nil ->
        nil

      @unset_double ->
        nil

      "" ->
        nil

      other when is_binary(other) ->
        Decimal.new(other)
    end
  end

  def to_float(str) do
    case str do
      nil ->
        nil

      "" ->
        nil

      other when is_binary(other) ->
        other
        |> Float.parse()
        |> elem(0)
    end
  rescue
    _ ->
      nil
  end

  def to_integer(str) do
    String.to_integer(str)
  rescue
    _ ->
      nil
  end

  def to_bool(str) when str in ["0", "1"] do
    String.to_integer(str) != 0
  end

  def to_bool(_) do
    nil
  end

  def parse_init_connection_timestamp(str) when is_binary(str) do
    case Regex.run(@timestamp_regex, str) do
      [_, date, time, timezone] ->
        parse_timestamp_str("#{date} #{time} #{@timezone_names_to_zone_id[timezone]}", "%y%m%d %H:%M:%S %Z")

      _ ->
        {:error, :unknown_timezone}
    end
  end

  def parse_timestamp_str(str, formatter \\ "%Y%m%d %H:%M:%S %Z")

  def parse_timestamp_str(str, formatter) when is_binary(str) do
    case Timex.parse(str, formatter, :strftime) do
      {:ok, ts} ->
        {:ok, Timex.Timezone.convert(ts, "Etc/UTC")}

      _ ->
        {:error, :invalid_args}
    end
  end

  def parse_timestamp_str(_, _) do
    {:error, :invalid_args}
  end
end
