defmodule IbEx.Client.Messages.MarketData.RequestHistoricalDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestHistoricalData
  alias IbEx.Client.Protocols.Traceable
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

  describe "new/7" do
    test "creates the message with valid inputs without date and time" do
      assert {:ok, msg} =
               RequestHistoricalData.new(@contract, nil, {1, :week}, {1, :hour}, :trades, false, false)

      assert msg.message_id == 20
      assert msg.contract == @contract
      assert msg.end_date_time == ""
      assert msg.duration == "1 W"
      assert msg.bar_size == "1 hour"
      assert msg.what_to_show == "TRADES"
      assert msg.use_rth == false
      assert msg.format_date == 2
      assert msg.keep_up_to_date == false
    end

    test "creates the message with valid date and time" do
      {:ok, date} = Date.new(2024, 08, 21)
      {:ok, time} = Time.new(13, 14, 15)
      {:ok, dt} = DateTime.new(date, time)

      assert {:ok, msg} =
               RequestHistoricalData.new(@contract, dt, {1, :week}, {1, :hour}, :trades, false, false)

      assert msg.message_id == 20
      assert msg.contract == @contract
      assert msg.end_date_time == "20240821-13:14:15"
      assert msg.duration == "1 W"
      assert msg.bar_size == "1 hour"
      assert msg.what_to_show == "TRADES"
      assert msg.use_rth == false
      assert msg.format_date == 2
      assert msg.keep_up_to_date == false
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      msg = %RequestHistoricalData{
        request_id: 123,
        contract: @contract,
        end_date_time: "",
        duration: "1 W",
        bar_size: "1 hour",
        what_to_show: "TRADES",
        use_rth: false,
        keep_up_to_date: false
      }

      contract_str = Enum.join(Contract.serialize(@contract, false), ", ")

      assert Traceable.to_s(msg) ==
               """
               --> MarketData.RequestHistoricalData{
                 request_id: 123,
                 contract: #{contract_str},
                 end_date_time: ,
                 duration: 1 W, 
                 bar_size: 1 hour,
                 what_to_show: TRADES,
                 use_rth: false,
                 format_date: 2,
                 keep_up_to_date: false
               }
               """
    end
  end
end
