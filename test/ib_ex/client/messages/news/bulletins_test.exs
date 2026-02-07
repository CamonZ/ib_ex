defmodule IbEx.Client.Messages.News.BulletinsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.Bulletins
  alias IbEx.Client.Protocols.Traceable

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
