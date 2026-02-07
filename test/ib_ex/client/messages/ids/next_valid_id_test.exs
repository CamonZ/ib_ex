defmodule IbEx.Client.Messages.Ids.NextValidIdTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.Ids.NextValidId
  alias IbEx.Client.Protocols.Traceable

  describe "Traceable" do
    test "to_s/2 returns a human-readable version of the message" do
      msg = %NextValidId{next_valid_id: 16}
      assert Traceable.to_s(msg) == "<-- %NextValidId{next_valid_id: 16}"
    end
  end
end
