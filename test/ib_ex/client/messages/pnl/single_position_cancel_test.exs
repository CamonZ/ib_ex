defmodule IbEx.Client.Messages.Pnl.SinglePositionCancelTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Pnl.SinglePositionCancel

  describe "new/0" do
    test "creates a new SinglePositionCancel message with valid message id" do
      assert {:ok, msg} = SinglePositionCancel.new("19001")

      assert msg.message_id == 95
      assert msg.request_id == "19001"
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = SinglePositionCancel.new("19001")

      assert inspect(msg) ==
               """
               --> Pnl.SinglePositionCancel{message_id: 95, request_id: 19001}
               """
    end
  end

  describe "String.Chars " do
    test "returns the binary representation of the message" do
      {:ok, msg} = SinglePositionCancel.new("19001")
      assert to_string(msg) == <<57, 53, 0, 49, 57, 48, 48, 49, 0>>
    end
  end
end
