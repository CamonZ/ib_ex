defmodule IbEx.Client.Messages.MarketData.RequestOptionChainTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestOptionChain
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

  @msg %RequestOptionChain{
    request_id: 123,
    message_id: 78,
    underlying_symbol: @contract.symbol,
    fut_fop_exchange: nil,
    underlying_sec_type: @contract.security_type,
    underlying_conid: @contract.conid
  }

  @attrs %{
    underlying_symbol: @contract.symbol,
    underlying_sec_type: @contract.security_type,
    underlying_conid: @contract.conid
  }

  describe "new/1" do
    test "creates the message with valid inputs" do
      assert {:ok, msg} =
               RequestOptionChain.new(@attrs)

      refute msg.request_id
      assert msg.message_id == 78
      assert msg.underlying_symbol == @contract.symbol
      assert msg.fut_fop_exchange == nil
      assert msg.underlying_sec_type == @contract.security_type
      assert msg.underlying_conid == @contract.conid
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a serializable string" do
      assert Kernel.to_string(@msg) ==
               <<55, 56, 0, 49, 50, 51, 0, 77, 82, 78, 65, 0, 0, 83, 84, 75, 0, 51, 52, 52, 56, 48, 57, 49, 48, 54, 0>>
    end
  end

  describe "Inspect implementation" do
    test "returns a human-readable version of the struct" do
      assert inspect(@msg) ==
               """
               --> MarketData.RequestOptionChain{
                 request_id: 123,
                 underlying_symbol: #{@contract.symbol},
                 fut_fop_exchange: ,
                 underlying_sec_type: #{@contract.security_type},
                 underlying_conid: #{@contract.conid},
               }
               """
    end
  end

  describe "Subscribable" do
    alias IbEx.Client.Protocols.Subscribable
    alias IbEx.Client.Subscriptions

    test "subscribes the message" do
      pid = self()
      table_ref = Subscriptions.initialize()
      {:ok, msg} = RequestOptionChain.new(@attrs)
      {:ok, subscribed_msg} = Subscribable.subscribe(msg, pid, table_ref)

      assert {:ok, ^pid} = Subscribable.lookup(subscribed_msg, table_ref)
    end
  end
end
