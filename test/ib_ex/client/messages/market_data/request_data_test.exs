defmodule IbEx.Client.Messages.MarketData.RequestDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestData
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Protocols.Subscribable
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

  describe "String.Chars implementation" do
    test "converts the message to a serializable string" do
      msg = %RequestData{
        message_id: 1,
        request_id: 123,
        contract: @contract,
        tick_list: "100,101,104",
        snapshot: true,
        regulatory_snapshot: false
      }

      assert to_string(msg) ==
               <<49, 0, 49, 49, 0, 49, 50, 51, 0, 51, 52, 52, 56, 48, 57, 49, 48, 54, 0, 77, 82, 78, 65, 0, 83, 84, 75,
                 0, 0, 48, 46, 48, 0, 0, 0, 83, 77, 65, 82, 84, 0, 73, 83, 76, 65, 78, 68, 0, 85, 83, 68, 0, 0, 0, 48,
                 0, 49, 48, 48, 44, 49, 48, 49, 44, 49, 48, 52, 0, 49, 0, 48, 0, 0>>
    end
  end

  describe "Inspect implementation" do
    test "returns a human-readable version of the struct" do
      msg = %RequestData{
        request_id: 123,
        contract: @contract,
        tick_list: "100,101,104",
        snapshot: true,
        regulatory_snapshot: false
      }

      contract_str = Enum.join(Contract.serialize(@contract, false), ", ")

      assert inspect(msg) ==
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
