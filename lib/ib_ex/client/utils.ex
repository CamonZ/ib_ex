defmodule IbEx.Client.Utils do
  @moduledoc """
    Common utils used when casting data into different types
  """

  @unset_double "1.7976931348623157E308"

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
        Decimal.new("0")

      other when is_binary(other) ->
        Decimal.new(other)
    end
  end
end
