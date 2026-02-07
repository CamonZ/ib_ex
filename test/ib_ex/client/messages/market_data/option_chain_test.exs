defmodule IbEx.Client.Messages.MarketData.OptionChainTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.OptionChain
  alias IbEx.Client.Protocols.Traceable

  @attrs %{
    request_id: "9001",
    exchange: "CBOE2",
    underlying_conid: "520512263",
    underlying_symbol: "GTLB",
    multiplier: "100",
    expirations_length: "7",
    expirations: ["20240920", "20240927", "20241004", "20241011", "20241018", "20241025", "20241101"],
    strikes_length: "9",
    strikes: [
      "42.5",
      "43.0",
      "43.5",
      "44.0",
      "44.5",
      "45.0",
      "45.5",
      "46.0",
      "46.5"
    ]
  }

  @msg %OptionChain{
    request_id: @attrs.request_id,
    exchange: @attrs.exchange,
    underlying_conid: @attrs.underlying_conid,
    underlying_symbol: @attrs.underlying_symbol,
    multiplier: @attrs.multiplier,
    expirations: @attrs.expirations,
    strikes: @attrs.strikes
  }

  describe "Traceab;e" do
    test "to_s/1 returns a human-readable version of the message" do
      assert Traceable.to_s(@msg) ==
               """
               <-- %MarketData.OptionChain{
                 request_id: 9001,
                 exchange: #{@msg.exchange},
                 underlying_conid: #{@msg.underlying_conid},
                 underlying_symbol: #{@msg.underlying_symbol},
                 multiplier: #{@msg.multiplier},
                 expirations: #{Enum.join(@msg.expirations, ", ")},
                 strikes: #{Enum.join(@msg.strikes, ", ")},
               }
               """
    end
  end
end
