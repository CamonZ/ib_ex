defmodule IbEx.Client.Messages.MarketData.TickNewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickNews
  alias IbEx.Client.Types.NewsHeadline

  describe "from_fields/1" do
    test "creates TickNews struct with valid fields" do
      fields = ["1", "1702847371145", "BZ", "BZ$123abcde", "Alien Invasion", "A:800015:L:en:K:n/a:C:0.6716986894607544"]

      assert {:ok, msg} = TickNews.from_fields(fields)
      headline = msg.headline

      assert msg.request_id == "1"
      assert match?(%NewsHeadline{}, headline)
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == TickNews.from_fields(["123"])
    end
  end

  describe "Inspect implementation" do
    test "inspects TickNews struct correctly" do
      msg = %TickNews{
        request_id: "1",
        headline: %NewsHeadline{
          title: "Alien Invasion!",
          timestamp: ~U[2023-12-17 19:34:39.033Z],
          provider: "FOO",
          provider_id: "FOO$12345abc",
          language: "en",
          sentiment: "n/a",
          extra_metadata: %{"A" => "15001", "C" => "0.234"}
        }
      }

      assert inspect(msg) ==
               """
               <-- %MarketData.TickNews{
                 request_id: 1,
                 headline: Alien Invasion!,
                 provider: FOO,
                 provider_id: FOO$12345abc,
                 language: en,
                 sentiment: n/a,
                 extra_metadata: %{"A" => "15001", "C" => "0.234"}
               }
               """
    end
  end
end
