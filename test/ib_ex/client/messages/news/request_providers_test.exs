defmodule IbEx.Client.Messages.News.RequestProvidersTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.RequestProviders
  alias IbEx.Client.Protocols.Traceable

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

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      request_providers = %RequestProviders{message_id: 1}
      inspected = Traceable.to_s(request_providers)

      assert inspected == "--> News.RequestProviders{}"
    end
  end
end
