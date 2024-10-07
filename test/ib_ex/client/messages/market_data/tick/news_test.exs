defmodule IbEx.Client.Messages.MarketData.Tick.NewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.Tick.News
  alias IbEx.Client.Types.NewsHeadline
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  @valid_fields [
    "1",
    "1702847371145",
    "BZ",
    "BZ$123abcde",
    "Alien Invasion",
    "A:800015:L:en:K:n/a:C:0.6716986894607544"
  ]

  describe "from_fields/1" do
    test "creates News struct with valid fields" do
      assert {:ok, msg} = News.from_fields(@valid_fields)
      headline = msg.headline

      assert msg.request_id == "1"
      assert match?(%NewsHeadline{}, headline)
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == News.from_fields(["123"])
    end
  end

  describe "Inspect implementation" do
    test "inspects News struct correctly" do
      msg = %News{
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
               <-- %MarketData.Tick.News{
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

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      {:ok, msg} = News.from_fields(@valid_fields)

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
