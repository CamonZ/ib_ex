defmodule IbEx.Client.Types.FamilyCodeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.FamilyCode

  describe "new/0" do
    test "creates a FamilyCode struct with default attributes" do
      assert FamilyCode.new() == %FamilyCode{
               account_id: nil,
               family_code_str: nil
             }
    end
  end

  describe "new/1" do
    test "creates a FamilyCode struct from a map" do
      params = %{account_id: "DU12345", family_code_str: "FAM001"}

      result = FamilyCode.new(params)

      assert result.account_id == "DU12345"
      assert result.family_code_str == "FAM001"
    end

    test "creates a FamilyCode struct from a keyword list" do
      params = [account_id: "DU12345", family_code_str: "FAM001"]

      result = FamilyCode.new(params)

      assert result.account_id == "DU12345"
      assert result.family_code_str == "FAM001"
    end
  end
end
