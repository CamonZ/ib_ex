defmodule IbEx.Client.Proto.Mapper.Helpers do
  @moduledoc """
  Domain-specific helper functions for proto mapping.

  Handles TagValue list <-> map conversion and IB sentinel value detection.
  Generic type conversions (to_decimal, to_float, to_integer, etc.) live in
  `IbEx.Client.Utils`.
  """

  @unset_double_value 1.7976931348623157e308
  @unset_integer_value 2_147_483_647

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
end
