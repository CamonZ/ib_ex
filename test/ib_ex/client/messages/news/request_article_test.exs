defmodule IbEx.Client.Messages.News.RequestArticleTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.RequestArticle
  alias IbEx.Client.Protocols.Traceable

  describe "new/3" do
    test "creates a RequestArticle struct with valid inputs" do
      assert {:ok, request_article} = RequestArticle.new(9001, "BZ", "BZ$12345abc")

      assert request_article.message_id == 84
      assert request_article.request_id == 9001
      assert request_article.provider_code == "BZ"
      assert request_article.provider_id == "BZ$12345abc"
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      request_article = %RequestArticle{
        request_id: 9001,
        provider_code: "BZ",
        provider_id: "BZ$12345abc"
      }

      assert Traceable.to_s(request_article) ==
               """
               <-- %News.RequestArticle{
                 request_id: 9001,
                 provider_code: BZ,
                 provider_id: BZ$12345abc
                }
               """
    end
  end
end
