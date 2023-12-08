defmodule IbEx.Client.Messages.MarketDepth.RequestDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.RequestData
  alias IbEx.Client.Types.Contract

  describe "new/4" do
    test "creates a RequestData struct with valid inputs" do
      contract = %Contract{symbol: "AAPL", security_type: "STK", exchange: "NSDQ"}

      assert {:ok, msg} = RequestData.new("90001", contract, 10, false)

      assert msg.message_id == 10
      assert msg.version == 5
      assert msg.request_id == "90001"
      assert msg.contract == contract
      assert msg.num_rows == 10
      refute msg.smart_depth?
    end
  end

  describe "String.Chars implementation" do
    test "converts RequestData struct to string" do
      contract = %Contract{symbol: "AAPL", security_type: "STK"}

      msg = %RequestData{
        message_id: 10,
        version: 5,
        request_id: "123",
        contract: contract,
        num_rows: 10,
        smart_depth?: true
      }

      assert to_string(msg) ==
               <<49, 48, 0, 53, 0, 49, 50, 51, 0, 48, 0, 65, 65, 80, 76, 0, 83, 84, 75, 0, 0, 48, 46, 48, 0, 0, 0, 83,
                 77, 65, 82, 84, 0, 0, 0, 0, 0, 49, 48, 0, 49, 0, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspects RequestData struct correctly" do
      contract = %Contract{symbol: "AAPL", security_type: "STK"}

      msg = %RequestData{
        request_id: "90001",
        contract: contract,
        num_rows: 10,
        smart_depth?: true
      }

      assert inspect(msg) ==
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
end
