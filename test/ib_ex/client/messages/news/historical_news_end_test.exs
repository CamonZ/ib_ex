defmodule IbEx.Client.Messages.News.HistoricalNewsEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.HistoricalNewsEnd
  alias IbEx.Client.Protocols.Traceable

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      assert Traceable.to_s(%HistoricalNewsEnd{request_id: "90001", has_more: true}) ==
               "<-- %News.HistoricalNewsEnd{request_id: 90001, has_more: true}"
    end
  end
end
