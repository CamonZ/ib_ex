defmodule IbEx.Client.Proto.ProtoRoundtripTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Protobuf.Contract
  alias IbEx.Client.Proto.Protobuf.ErrorMessage
  alias IbEx.Client.Proto.Protobuf.PlaceOrderRequest
  alias IbEx.Client.Proto.Protobuf.Order
  alias IbEx.Client.Proto.Protobuf.ComboLeg

  describe "Contract encode/decode roundtrip" do
    test "preserves all scalar field values" do
      contract = %Contract{
        con_id: 265_598,
        symbol: "AAPL",
        sec_type: "STK",
        exchange: "SMART",
        primary_exch: "NASDAQ",
        currency: "USD",
        local_symbol: "AAPL",
        trading_class: "NMS",
        strike: 0.0,
        include_expired: false
      }

      encoded = Contract.encode(contract)
      decoded = Contract.decode(encoded)

      assert decoded.con_id == 265_598
      assert decoded.symbol == "AAPL"
      assert decoded.sec_type == "STK"
      assert decoded.exchange == "SMART"
      assert decoded.primary_exch == "NASDAQ"
      assert decoded.currency == "USD"
      assert decoded.local_symbol == "AAPL"
      assert decoded.trading_class == "NMS"
      assert decoded.strike == 0.0
      assert decoded.include_expired == false
    end

    test "preserves optional fields when set to nil" do
      contract = %Contract{
        con_id: 12_345,
        symbol: "MSFT"
      }

      encoded = Contract.encode(contract)
      decoded = Contract.decode(encoded)

      assert decoded.con_id == 12_345
      assert decoded.symbol == "MSFT"
      assert decoded.sec_type == nil
      assert decoded.exchange == nil
      assert decoded.currency == nil
      assert decoded.delta_neutral_contract == nil
    end

    test "preserves repeated ComboLeg fields" do
      contract = %Contract{
        con_id: 100_000,
        symbol: "SPY",
        sec_type: "BAG",
        combo_legs: [
          %ComboLeg{con_id: 200_001, ratio: 1, action: "BUY", exchange: "SMART"},
          %ComboLeg{con_id: 200_002, ratio: 1, action: "SELL", exchange: "SMART"}
        ]
      }

      encoded = Contract.encode(contract)
      decoded = Contract.decode(encoded)

      assert length(decoded.combo_legs) == 2

      [leg1, leg2] = decoded.combo_legs
      assert leg1.con_id == 200_001
      assert leg1.ratio == 1
      assert leg1.action == "BUY"
      assert leg1.exchange == "SMART"

      assert leg2.con_id == 200_002
      assert leg2.ratio == 1
      assert leg2.action == "SELL"
      assert leg2.exchange == "SMART"
    end
  end

  describe "ErrorMessage encode/decode roundtrip" do
    test "preserves all field values" do
      error = %ErrorMessage{
        id: 1,
        error_time: 1_706_200_000_000,
        error_code: 200,
        error_msg: "No security definition has been found for the request",
        advanced_order_reject_json: ""
      }

      encoded = ErrorMessage.encode(error)
      decoded = ErrorMessage.decode(encoded)

      assert decoded.id == 1
      assert decoded.error_time == 1_706_200_000_000
      assert decoded.error_code == 200
      assert decoded.error_msg == "No security definition has been found for the request"
      assert decoded.advanced_order_reject_json == ""
    end
  end

  describe "PlaceOrderRequest with nested messages" do
    test "preserves nested Contract and Order fields" do
      request = %PlaceOrderRequest{
        order_id: 42,
        contract: %Contract{
          con_id: 265_598,
          symbol: "AAPL",
          sec_type: "STK",
          exchange: "SMART",
          currency: "USD"
        },
        order: %Order{
          order_id: 42,
          action: "BUY",
          total_quantity: "100",
          order_type: "LMT",
          lmt_price: 150.50,
          tif: "DAY",
          transmit: true
        }
      }

      encoded = PlaceOrderRequest.encode(request)
      decoded = PlaceOrderRequest.decode(encoded)

      assert decoded.order_id == 42

      assert decoded.contract.con_id == 265_598
      assert decoded.contract.symbol == "AAPL"
      assert decoded.contract.sec_type == "STK"
      assert decoded.contract.exchange == "SMART"
      assert decoded.contract.currency == "USD"

      assert decoded.order.order_id == 42
      assert decoded.order.action == "BUY"
      assert decoded.order.total_quantity == "100"
      assert decoded.order.order_type == "LMT"
      assert decoded.order.lmt_price == 150.50
      assert decoded.order.tif == "DAY"
      assert decoded.order.transmit == true
    end
  end

  describe "binary encoding produces valid protobuf" do
    test "encoded binary is non-empty for populated struct" do
      contract = %Contract{con_id: 1, symbol: "TEST"}
      encoded = Contract.encode(contract)

      assert is_binary(encoded)
      assert byte_size(encoded) > 0
    end

    test "encoding an empty struct produces minimal binary" do
      contract = %Contract{}
      encoded = Contract.encode(contract)

      assert is_binary(encoded)
    end
  end
end
