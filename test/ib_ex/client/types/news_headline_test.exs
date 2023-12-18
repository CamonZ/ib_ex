defmodule IbEx.Client.Types.NewsHeadlineTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.NewsHeadline

  describe "from_news_tick/1" do
    test "creates NewsHeadline struct with valid fields" do
      assert {:ok, headline} =
               NewsHeadline.from_news_tick([
                 "1702841679033",
                 "BZ",
                 "BZ$cfeeacfe",
                 "A title",
                 "A:800015:L:en:K:n/a:C:0.6716986894607544"
               ])

      assert headline.timestamp == ~U[2023-12-17 19:34:39.033Z]
      assert headline.provider == "BZ"
      assert headline.provider_id == "BZ$cfeeacfe"
      assert headline.title == "A title"
      assert headline.language == "en"
      assert headline.sentiment == "n/a"
      assert headline.extra_metadata == %{"A" => "800015", "C" => "0.6716986894607544"}
    end

    test "returns an error with invalid timestamp" do
      assert {:error, :invalid_args} ==
               NewsHeadline.from_news_tick(["invalid", "Provider", "ID", "Title", "L:EN:K:Positive"])
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == NewsHeadline.from_news_tick(["1617558433000", "Provider"])
    end
  end
end
