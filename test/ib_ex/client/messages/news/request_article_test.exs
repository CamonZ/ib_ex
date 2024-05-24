defmodule IbEx.Client.Messages.News.RequestArticleTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.RequestArticle

  describe "new/3" do
    test "creates a RequestArticle struct with valid inputs" do
      assert {:ok, request_article} = RequestArticle.new(9001, "BZ", "BZ$12345abc")

      assert request_article.message_id == 84
      assert request_article.request_id == 9001
      assert request_article.provider_code == "BZ"
      assert request_article.provider_id == "BZ$12345abc"
    end
  end

  describe "String.Chars implementation" do
    test "converts RequestArticle struct to string" do
      request_article = %RequestArticle{
        message_id: "84",
        request_id: 9001,
        provider_code: "BZ",
        provider_id: "BZ$12345abc"
      }

      assert to_string(request_article) ==
               <<56, 52, 0, 57, 48, 48, 49, 0, 66, 90, 0, 66, 90, 36, 49, 50, 51, 52, 53, 97, 98, 99, 0, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspects RequestArticle struct correctly" do
      request_article = %RequestArticle{
        request_id: 9001,
        provider_code: "BZ",
        provider_id: "BZ$12345abc"
      }

      assert inspect(request_article) ==
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
