defmodule IbEx.Client.UtilsTest do
  use ExUnit.Case

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
end
