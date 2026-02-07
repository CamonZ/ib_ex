defmodule IbEx.Client.Messages.TickByTickData.CancelTickByTickDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.TickByTickData.CancelTickByTickData
  alias IbEx.Client.Protocols.Traceable

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

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      {:ok, msg} = CancelTickByTickData.new(19001)
      assert Traceable.to_s(msg) == "--> CancelTickByTickData{message_id: 98, request_id: 19001}"
    end
  end
end
