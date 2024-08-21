defmodule IbEx.Client.Messages.MarketData.RequestHistoricalDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestHistoricalData
  alias IbEx.Client.Types.Contract

  @contract %Contract{
    conid: "344809106",
    symbol: "MRNA",
    security_type: "STK",
    last_trade_date_or_contract_month: "",
    strike: "0.0",
    right: "",
    multiplier: "",
    exchange: "SMART",
    currency: "USD",
    local_symbol: "",
    primary_exchange: "ISLAND",
    trading_class: "",
    include_expired: false,
    security_id_type: "",
    security_id: "",
    combo_legs_description: nil,
    combo_legs: [],
    delta_neutral_contract: nil,
    description: "MODERNA INC",
    issuer_id: ""
  }

  describe "new/8" do
    test "creates the message with valid inputs" do
      assert {:ok, msg} =
               RequestHistoricalData.new(@contract, nil, {1, :week}, {1, :hour}, :trades, false, false)

      assert msg.message_id == 20
      assert msg.contract == @contract
      assert msg.end_date_time == ""
      assert msg.duration == "1 W"
      assert msg.bar_size == "1 hour"
      assert msg.what_to_show == "TRADES"
      assert msg.use_rth == 0
      assert msg.format_date == 2
      assert msg.keep_up_to_date == 0
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a serializable string" do
      msg = %RequestHistoricalData{
        request_id: 123,
        contract: @contract,
        end_date_time: nil,
        duration: {1, :week},
        bar_size: {1, :hour},
        what_to_show: :trades,
        use_rth: false,
        keep_up_to_date: false
      }

      assert Kernel.to_string(msg) ==
               <<0, 49, 50, 51, 0, 51, 52, 52, 56, 48, 57, 49, 48, 54, 0, 77, 82, 78, 65, 0, 83, 84, 75, 0, 0, 48, 46,
                 48, 0, 0, 0, 83, 77, 65, 82, 84, 0, 73, 83, 76, 65, 78, 68, 0, 85, 83, 68, 0, 0, 0, 48, 0, 0, 0, 0, 48,
                 0, 116, 114, 97, 100, 101, 115, 0, 48, 0, 48, 0, 0>>
    end
  end

  describe "Inspect implementation" do
    @describetag :skip
    test "returns a human-readable version of the struct" do
      msg = %RequestHistoricalData{
        request_id: 123,
        contract: @contract,
        end_date_time: nil,
        duration: {1, :week},
        bar_size: {1, :hour},
        what_to_show: :trades,
        use_rth: false,
        keep_up_to_date: false
      }

      contract_str = Enum.join(Contract.serialize(@contract, false), ", ")

      assert inspect(msg) ==
               """
               --> MarketData.RequestHistoricalData{
                 request_id: 123,
                 contract: #{contract_str},
                 end_date_time: ,
                 duration: 1 W, 
                 bar_size: 1 hour,
                 what_to_show: TRADES,
                 use_rth: 0,
                 format_date: 2,
                 keep_up_to_date: 0
               }
               """
    end
  end
end
