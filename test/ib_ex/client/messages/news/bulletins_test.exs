defmodule IbEx.Client.Messages.News.BulletinsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.Bulletins
  alias IbEx.Client.Protocols.Traceable

  describe "from_fields/1" do
    test "creates a regular_news message" do
      fields = ["1", "Some news message", "NYSE"]

      {:ok, msg} = Bulletins.from_fields(fields)

      assert msg.type == "regular_news"
      assert msg.message == "Some news message"
      assert msg.exchange == "NYSE"
    end

    test "creates a exchange_not_available message" do
      fields = ["2", "Some news message", "NYSE"]

      {:ok, msg} = Bulletins.from_fields(fields)

      assert msg.type == "exchange_not_available"
      assert msg.message == "Some news message"
      assert msg.exchange == "NYSE"
    end

    test "creates a exchange_available message" do
      fields = ["3", "Some news message", "NYSE"]

      {:ok, msg} = Bulletins.from_fields(fields)

      assert msg.type == "exchange_available"
      assert msg.message == "Some news message"
      assert msg.exchange == "NYSE"
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %Bulletins{
        type: "regular_news",
        message: "Some news message",
        exchange: "NYSE"
      }

      assert Traceable.to_s(msg) ==
               """
               <-- %News.Bulletins{
                 type: regular_news,
                 message: Some news message,
                 exchange: NYSE
               }
               """
    end
  end
end
