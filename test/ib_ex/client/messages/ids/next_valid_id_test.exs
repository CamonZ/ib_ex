defmodule IbEx.Client.Messages.Ids.NextValidIdTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.Ids.NextValidId
  alias IbEx.Client.Protocols.Traceable

  describe "from_fields/1" do
    test "parses valid version and id strings into a NextValidId struct" do
      assert {:ok, next_valid_id} = NextValidId.from_fields(["1", "16"])
      assert next_valid_id.version == 1
      assert next_valid_id.next_valid_id == 16
    end

    test "returns an error tuple for invalid input" do
      assert {:error, :unexpected_error} = NextValidId.from_fields(["abc", "xyz"])
    end

    test "returns error for incorrect number of arguments" do
      assert {:error, :invalid_args} = NextValidId.from_fields(["1"])
    end
  end

  describe "Traceable" do
    test "to_s/2 returns a human-readable version of the message" do
      next_valid_id = NextValidId.from_fields(["1", "16"]) |> elem(1)
      assert Traceable.to_s(next_valid_id) == "<-- %NextValidId{version: 1, next_valid_id: 16}"
    end
  end
end
