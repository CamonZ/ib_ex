defmodule IbEx.Client.Messages.MarketDepth.RequestDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.RequestData
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Subscriptions

  describe "new/4" do
    test "creates a RequestData struct with valid inputs" do
      contract = %Contract{symbol: "AAPL", security_type: "STK", exchange: "NSDQ"}

      assert {:ok, msg} = RequestData.new(contract, 10, false)

      assert msg.message_id == 10
      assert msg.contract == contract
      assert msg.num_rows == 10
      refute msg.smart_depth?
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      contract = %Contract{symbol: "AAPL", security_type: "STK"}

      msg = %RequestData{
        request_id: 90001,
        contract: contract,
        num_rows: 10,
        smart_depth?: true
      }

      assert Traceable.to_s(msg) ==
               """
               --> MarketDepth.RequestData{
                 request_id: 90001,
                 contract: STK AAPL,
                 num_rows: 10,
                 smart_depth?: true
               }
               """
    end
  end

  describe "Subscribable" do
    test "subscribe/3 subscribes incoming messages with the msg's request id to the given pid" do
      table_ref = Subscriptions.initialize()

      contract = %Contract{symbol: "AAPL", security_type: "STK", exchange: "NSDQ"}
      assert {:ok, msg} = RequestData.new(contract, 10, false)

      assert {:ok, msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert msg.request_id == 1

      assert {:ok, pid} = Subscriptions.lookup(table_ref, to_string(msg.request_id))

      assert pid == self()
    end
  end
end
