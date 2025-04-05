defmodule IbEx.Client.Messages.Pnl.AllPositionsCancelTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Pnl.AllPositionsCancel
  alias IbEx.Client.Protocols.Traceable

  describe "new/0" do
    test "creates a new AllPositionsCancel message with valid message id" do
      assert {:ok, msg} = AllPositionsCancel.new("19001")

      assert msg.message_id == 93
      assert msg.request_id == "19001"
    end
  end

  describe "Traceable" do
    test "to_s/2 returns a human-readable version of the message" do
      {:ok, msg} = AllPositionsCancel.new("19001")

      assert Traceable.to_s(msg) ==
               """
               --> Pnl.AllPositionsCancel{message_id: 93, request_id: 19001}
               """
    end
  end

  describe "String.Chars " do
    test "returns the binary representation of the message" do
      {:ok, msg} = AllPositionsCancel.new("19001")
      assert to_string(msg) == <<57, 51, 0, 49, 57, 48, 48, 49, 0>>
    end
  end
end
