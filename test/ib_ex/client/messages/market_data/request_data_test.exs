defmodule IbEx.Client.Messages.MarketData.RequestDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestData
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

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

  describe "new/5" do
    test "creates the message with valid inputs" do
      assert {:ok, msg} = RequestData.new(@contract, "100,101,104", false, false)

      assert msg.message_id == 1
      assert msg.contract == @contract
      assert msg.tick_list == "100,101,104"
      refute msg.snapshot
      refute msg.regulatory_snapshot
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      msg = %RequestData{
        request_id: 123,
        contract: @contract,
        tick_list: "100,101,104",
        snapshot: true,
        regulatory_snapshot: false
      }

      contract_str = Enum.join(Contract.serialize(@contract, false), ", ")

      assert Traceable.to_s(msg) ==
               """
               --> MarketData.RequestData{
                 request_id: 123,
                 contract: #{contract_str},
                 tick_list: 100,101,104,
                 snapshot: true,
                 regulatory_snapshot: false
               }
               """
    end
  end

  describe "Subscribable" do
    test "subscribe/3 subscribes incoming messages with the msg's request id to the given pid" do
      table_ref = Subscriptions.initialize()
      contract = Contract.new(%{conid: "265598", symbol: "AAPL", security_type: "STK"})

      {:ok, msg} = RequestData.new(contract, "100,101,104", false, false)

      assert {:ok, msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert msg.request_id == 1

      assert {:ok, pid} = Subscriptions.lookup(table_ref, to_string(msg.request_id))

      assert pid == self()
    end
  end
end
