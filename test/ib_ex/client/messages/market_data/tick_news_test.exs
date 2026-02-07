defmodule IbEx.Client.Messages.MarketData.TickNewsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickNews
  alias IbEx.Client.Types.NewsHeadline
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
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

      assert Traceable.to_s(msg) ==
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

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      msg = %TickNews{request_id: "1", headline: %NewsHeadline{}}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
