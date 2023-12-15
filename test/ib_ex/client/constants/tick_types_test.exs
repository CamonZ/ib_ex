defmodule IbEx.Client.Constants.TickTypesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Constants.TickTypes

  describe "to_atom/1" do
    test "converts integer index to corresponding atom" do
      assert TickTypes.to_atom(0) == {:ok, :bid_size}
      assert TickTypes.to_atom(1) == {:ok, :bid}
    end

    test "returns error for invalid index" do
      assert TickTypes.to_atom(-1) == {:error, :invalid_args}
      assert TickTypes.to_atom("invalid") == {:error, :invalid_args}
    end
  end

  describe "size_related_type?/1" do
    test "returns true for size-related tick types" do
      assert TickTypes.size_related_type?(:bid_size) == true
    end

    test "returns false for non-size-related tick types" do
      assert TickTypes.size_related_type?(:ask) == false
    end

    test "returns false on invalid args" do
      assert TickTypes.size_related_type?("foobarbaz") == false
    end
  end
end
