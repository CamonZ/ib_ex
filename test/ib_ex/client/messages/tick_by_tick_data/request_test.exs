defmodule IbEx.Client.Messages.TickByTickData.RequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.TickByTickData.Request
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Protocols.Traceable

  setup do
    contract = %Contract{symbol: "AAPL", security_type: "STK", exchange: "NASDAQ", currency: "USD"}
    {:ok, contract: contract}
  end

  describe "new/5" do
    test "creates a new TickByTickData Request with valid inputs", %{contract: contract} do
      {:ok, msg} = Request.new(contract, 123, "Last", 10, true)
      assert msg.message_id == 97
      assert msg.request_id == 123
      assert msg.contract.symbol == "AAPL"
      assert msg.tick_type == "Last"
      assert msg.number_of_ticks == 10
      assert msg.ignore_size == true
    end

    test "creates a new TickByTickData Request with only 3 params", %{contract: contract} do
      {:ok, msg} = Request.new(contract, 123, "Last")

      assert msg.message_id == 97
      assert msg.request_id == 123
      assert msg.contract.symbol == "AAPL"
      assert msg.tick_type == "Last"
      assert msg.number_of_ticks == 0
      assert msg.ignore_size == false
    end

    test "returns error for invalid tick type", %{contract: contract} do
      assert {:error, :invalid_args} = Request.new(contract, 123, "InvalidType", 10, true)
    end

    test "returns error for negative number of ticks", %{contract: contract} do
      assert {:error, :invalid_args} = Request.new(contract, 123, "Last", -1, true)
    end

    test "to_string returns the correct binary representation of the message", %{contract: contract} do
      {:ok, msg} = Request.new(contract, 123, "Last", 10, true)

      assert to_string(msg) ==
               <<57, 55, 0, 49, 50, 51, 0, 48, 0, 65, 65, 80, 76, 0, 83, 84, 75, 0, 0, 48, 46, 48, 0, 0, 0, 78, 65, 83,
                 68, 65, 81, 0, 0, 85, 83, 68, 0, 0, 0, 76, 97, 115, 116, 0, 49, 48, 0, 49, 0>>
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct", %{contract: contract} do
      {:ok, msg} = Request.new(contract, 123, "Last", 10, true)

      assert Traceable.to_s(msg) == "-->
        TickByTickData{
          message_id: 97,
          request_id: 123,
          contract: AAPL,
          tick_type: Last,
          number_of_ticks: 10,
          ignore_size: true
        }"
    end
  end
end
