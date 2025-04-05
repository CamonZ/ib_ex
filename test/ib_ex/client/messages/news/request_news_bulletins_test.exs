defmodule IbEx.Client.Messages.News.RequestBulletinsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.RequestBulletins
  alias IbEx.Client.Protocols.Traceable

  describe "new/1" do
    test "creates the message with all_messages set to false by default" do
      assert {:ok, msg} = RequestBulletins.new()

      assert msg.message_id == 12
      assert msg.version == 1
      assert msg.all_messages == false
    end

    test "creates the message with all_messages set to true" do
      assert {:ok, msg} = RequestBulletins.new(true)

      assert msg.message_id == 12
      assert msg.version == 1
      assert msg.all_messages == true
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a binary for serialization" do
      msg = %RequestBulletins{message_id: 12, all_messages: true}
      assert to_string(msg) == <<49, 50, 0, 49, 0, 49, 0>>
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      assert Traceable.to_s(%RequestBulletins{all_messages: true}) == "--> News.RequestBulletins{all_messages: true}"
    end
  end
end
