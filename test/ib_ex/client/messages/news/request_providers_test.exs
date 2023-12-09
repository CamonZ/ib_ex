defmodule IbEx.Client.Messages.News.RequestProvidersTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.RequestProviders

  describe "new/0" do
    test "creates a RequestProviders struct with valid message id" do
      assert {:ok, %RequestProviders{message_id: 85}} = RequestProviders.new()
    end
  end

  describe "String.Chars implementation" do
    test "converts RequestProviders struct to string" do
      assert to_string(%RequestProviders{message_id: 85}) == <<56, 53, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspects RequestProviders struct correctly" do
      request_providers = %RequestProviders{message_id: 1}
      inspected = inspect(request_providers)

      assert inspected ==
               """
               --> News.RequestProviders{}
               """
    end
  end
end
