defmodule IbEx.Client.Messages.News.HistoricalNewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.HistoricalNews
  alias IbEx.Client.Protocols.Traceable

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %HistoricalNews{
        request_id: "123",
        timestamp: "2021-12-31T23:59:59Z",
        provider_code: "BRFG",
        article_id: "ART123",
        headline: "Breaking News"
      }

      assert Traceable.to_s(msg) ==
               """
               <-- %News.HistoricalNews{
                 request_id: 123,
                 timestamp: 2021-12-31T23:59:59Z,
                 provider_code: BRFG,
                 article_id: ART123,
                 headline: Breaking News
                }
               """
    end
  end
end
