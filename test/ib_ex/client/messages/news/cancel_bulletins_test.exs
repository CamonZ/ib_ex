defmodule IbEx.Client.Messages.News.CancelBulletinsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.CancelBulletins
  alias IbEx.Client.Protocols.Traceable

  describe "new/0" do
    test "creates the message successfully" do
      assert {:ok, msg} = CancelBulletins.new()

      assert msg.message_id == 13
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      assert Traceable.to_s(%CancelBulletins{}) == "--> News.CancelBulletins{}"
    end
  end
end
