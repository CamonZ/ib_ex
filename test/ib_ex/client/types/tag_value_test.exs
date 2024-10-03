defmodule IbEx.Client.Types.TagValueTest do
  use ExUnit.Case, async: true
  alias IbEx.Client.Types.TagValue

  describe "new/1" do
    test "creates a TagValue struct with valid attributes" do
      attrs = %{
        tag: "tag",
        value: "value"
      }

      assert TagValue.new(attrs) == %TagValue{
               tag: "tag",
               value: "value"
             }
    end
  end
end
