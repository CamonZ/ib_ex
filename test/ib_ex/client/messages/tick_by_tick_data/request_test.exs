defmodule IbEx.Client.Messages.TickByTickData.RequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.TickByTickData.Request
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Subscriptions
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  setup do
    contract = %Contract{symbol: "AAPL", security_type: "STK", exchange: "NASDAQ", currency: "USD"}
    {:ok, contract: contract}
  end

  describe "new/4" do
    test "creates a new TickByTickData Request with valid inputs", %{contract: contract} do
      table_ref = Subscriptions.initialize()
      {:ok, msg} = Request.new(contract, "Last", 10, true)

      {:ok, msg} = Subscribable.subscribe(msg, self(), table_ref)

      assert msg.message_id == 97
      assert msg.contract.symbol == "AAPL"
      assert msg.tick_type == "Last"
      assert msg.number_of_ticks == 10
      assert msg.ignore_size == true
    end

    test "creates a new TickByTickData Request with only 2 params", %{contract: contract} do
      {:ok, msg} = Request.new(contract, "Last")

      assert msg.message_id == 97
      assert msg.contract.symbol == "AAPL"
      assert msg.tick_type == "Last"
      assert msg.number_of_ticks == 0
      assert msg.ignore_size == false
    end

    test "returns error for invalid tick type", %{contract: contract} do
      assert {:error, :invalid_args} = Request.new(contract, "InvalidType", 10, true)
    end

    test "returns error for negative number of ticks", %{contract: contract} do
      assert {:error, :invalid_args} = Request.new(contract, "Last", -1, true)
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct", %{contract: contract} do
      {:ok, msg} = Request.new(contract, "Last", 10, true)
      msg = %{msg | request_id: 1}

      assert Traceable.to_s(msg) == "-->
        TickByTickData.Request{
          message_id: 97,
          request_id: 1,
          contract: AAPL,
          tick_type: Last,
          number_of_ticks: 10,
          ignore_size: true
        }"
    end
  end

  describe "Subscribable" do
    test "subscribe/3 subscribes incoming messages with the msg's request id to the given pid", %{contract: contract} do
      table_ref = Subscriptions.initialize()
      {:ok, msg} = Request.new(contract, "Last", 10, true)

      assert {:ok, msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert msg.request_id == 1

      assert {:ok, pid} = Subscriptions.lookup(table_ref, to_string(msg.request_id))

      assert pid == self()
    end
  end
end
