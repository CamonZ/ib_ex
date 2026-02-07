defmodule IbEx.Client.Types.IneligibilityReasonTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.IneligibilityReason

  describe "new/0" do
    test "creates an IneligibilityReason struct with default attributes" do
      assert IneligibilityReason.new() == %IneligibilityReason{
               id: nil,
               description: nil
             }
    end
  end

  describe "new/1" do
    test "creates an IneligibilityReason struct from a map" do
      params = %{id: "NO_SHORT", description: "Short selling not available"}

      result = IneligibilityReason.new(params)

      assert result.id == "NO_SHORT"
      assert result.description == "Short selling not available"
    end

    test "creates an IneligibilityReason struct from a keyword list" do
      params = [id: "NO_MARGIN", description: "Margin not available"]

      result = IneligibilityReason.new(params)

      assert result.id == "NO_MARGIN"
      assert result.description == "Margin not available"
    end
  end
end
