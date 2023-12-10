defmodule IbEx.Client.Messages.News.CancelBulletinsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.CancelBulletins

  describe "new/0" do
    test "creates the message successfully" do
      assert {:ok, msg} = CancelBulletins.new()

      assert msg.message_id == 13
      assert msg.version == 1
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a binary for serialization" do
      msg = %CancelBulletins{message_id: 13}
      assert to_string(msg) == <<49, 51, 0, 49, 0>>
    end
  end

  describe "Inspect implementation" do
    test "returns a human-readable version of the struct" do
      assert inspect(%CancelBulletins{}) == "--> News.CancelBulletins{}"
    end
  end
end
