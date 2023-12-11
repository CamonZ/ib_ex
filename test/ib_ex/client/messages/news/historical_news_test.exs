defmodule IbEx.Client.Messages.News.HistoricalNewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.HistoricalNews

  describe "from_fields/1" do
    test "creates HistoricalNews struct with valid fields" do
      assert {:ok, msg} = HistoricalNews.from_fields(["123", "2021-12-31T23:59:59Z", "BRFG", "ART123", "Breaking News"])

      assert msg.request_id == "123"
      assert msg.timestamp == "2021-12-31T23:59:59Z"
      assert msg.provider_code == "BRFG"
      assert msg.article_id == "ART123"
      assert msg.headline == "Breaking News"
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == HistoricalNews.from_fields(["123", "2021-12-31T23:59:59Z", "BRFG"])
    end
  end

  describe "Inspect implementation" do
    test "returns a human-readable version of the message" do
      msg = %HistoricalNews{
        request_id: "123",
        timestamp: "2021-12-31T23:59:59Z",
        provider_code: "BRFG",
        article_id: "ART123",
        headline: "Breaking News"
      }

      assert inspect(msg) ==
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
