defmodule IbEx.Client.Messages.TickByTickData.CancelTickByTickDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.TickByTickData.CancelTickByTickData

  describe "new/0" do
    test "creates a new CancelTickByTickData request with valid message id" do
      assert {:ok, msg} = CancelTickByTickData.new(19001)

      assert msg.message_id == 98
      assert msg.request_id == 19001
    end

    test "handles error when called with an invalid arg" do
      assert {:error, :invalid_args} == CancelTickByTickData.new("5")
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = CancelTickByTickData.new(19001)
      assert inspect(msg) == "--> CancelTickByTickData{message_id: 98, request_id: 19001}"
    end
  end

  describe "String.Chars " do
    test "returns the binary representation of the message" do
      {:ok, msg} = CancelTickByTickData.new(19001)
      assert to_string(msg) == <<57, 56, 0, 49, 57, 48, 48, 49, 0>>
    end
  end
end
