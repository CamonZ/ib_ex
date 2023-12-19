defmodule IbEx.Client.Types.NewsArticleTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.NewsArticle

  describe "from_news_tick/1" do
    test "creates NewsArticle struct with valid fields" do
      assert {:ok, article} =
               NewsArticle.from_article_data([
                 "0",
                 "This is the content of the news article."
               ])

      assert article.type == "0"
      assert article.content == "This is the content of the news article."
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == NewsArticle.from_article_data(["OnlyType"])
    end
  end
end
