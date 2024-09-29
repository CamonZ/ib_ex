defmodule IbEx.Client.Messages.MarketData.OptionChainTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.OptionChain

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

  @fields [
            "75",
            @attrs.request_id,
            @attrs.exchange,
            @attrs.underlying_conid,
            @attrs.underlying_symbol,
            @attrs.multiplier,
            @attrs.expirations_length
          ] ++ @attrs.expirations ++ [@attrs.strikes_length] ++ @attrs.strikes

  @msg %OptionChain{
    request_id: @attrs.request_id,
    exchange: @attrs.exchange,
    underlying_conid: @attrs.underlying_conid,
    underlying_symbol: @attrs.underlying_symbol,
    multiplier: @attrs.multiplier,
    expirations: @attrs.expirations,
    strikes: @attrs.strikes
  }

  describe "from_fields/1" do
    test "creates OptionChain struct with valid fields" do
      assert {:ok, msg} = OptionChain.from_fields(@fields)

      assert msg.request_id == @attrs.request_id
      assert msg.exchange == @attrs.exchange
      assert msg.underlying_conid == @attrs.underlying_conid
      assert msg.underlying_symbol == @attrs.underlying_symbol
      assert msg.multiplier == @attrs.multiplier
      assert msg.expirations == @attrs.expirations
      assert msg.strikes == @attrs.strikes
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == OptionChain.from_fields(["123", "1"])
    end
  end

  describe "Inspect implementation" do
    test "inspects OptionChain struct correctly" do
      assert inspect(@msg) ==
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
