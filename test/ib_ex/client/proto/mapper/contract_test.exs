defmodule IbEx.Client.Proto.Mapper.ContractTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Mapper.Contract, as: ContractMapper

  alias IbEx.Client.Types.Contract, as: DomainContract
  alias IbEx.Client.Types.Contract.ComboLeg, as: DomainComboLeg
  alias IbEx.Client.Types.Contract.DeltaNeutral, as: DomainDeltaNeutral

  alias IbEx.Client.Proto.Protobuf.Contract, as: ProtoContract
  alias IbEx.Client.Proto.Protobuf.ComboLeg, as: ProtoComboLeg
  alias IbEx.Client.Proto.Protobuf.DeltaNeutralContract, as: ProtoDeltaNeutral

  describe "to_proto/1" do
    test "converts all scalar fields correctly" do
      contract = %DomainContract{
        conid: "265598",
        symbol: "AAPL",
        security_type: "STK",
        last_trade_date_or_contract_month: "20240119",
        strike: "150.0",
        right: "C",
        multiplier: "100",
        exchange: "SMART",
        primary_exchange: "NASDAQ",
        currency: "USD",
        local_symbol: "AAPL",
        trading_class: "NMS",
        security_id_type: "CUSIP",
        security_id: "037833100",
        description: "Apple Inc",
        issuer_id: "ISID123",
        include_expired: true
      }

      proto = ContractMapper.to_proto(contract)

      assert %ProtoContract{} = proto
      assert proto.con_id == 265_598
      assert proto.symbol == "AAPL"
      assert proto.sec_type == "STK"
      assert proto.last_trade_date_or_contract_month == "20240119"
      assert proto.strike == 150.0
      assert proto.right == "C"
      assert proto.multiplier == 100.0
      assert proto.exchange == "SMART"
      assert proto.primary_exch == "NASDAQ"
      assert proto.currency == "USD"
      assert proto.local_symbol == "AAPL"
      assert proto.trading_class == "NMS"
      assert proto.sec_id_type == "CUSIP"
      assert proto.sec_id == "037833100"
      assert proto.description == "Apple Inc"
      assert proto.issuer_id == "ISID123"
      assert proto.include_expired == true
    end

    test "converts combo_legs list" do
      contract = %DomainContract{
        conid: "100000",
        symbol: "SPY",
        security_type: "BAG",
        combo_legs: [
          %DomainComboLeg{
            conid: 200_001,
            ratio: 1,
            action: "BUY",
            exchange: "SMART",
            open_close: 0,
            short_sale_slot: 0,
            designated_location: "loc1",
            exempt_code: -1
          },
          %DomainComboLeg{
            conid: 200_002,
            ratio: 1,
            action: "SELL",
            exchange: "SMART",
            open_close: 2,
            short_sale_slot: 1,
            designated_location: nil,
            exempt_code: 0
          }
        ]
      }

      proto = ContractMapper.to_proto(contract)

      assert length(proto.combo_legs) == 2
      [leg1, leg2] = proto.combo_legs

      assert %ProtoComboLeg{} = leg1
      assert leg1.con_id == 200_001
      assert leg1.ratio == 1
      assert leg1.action == "BUY"
      assert leg1.exchange == "SMART"
      assert leg1.open_close == 0
      assert leg1.short_sales_slot == 0
      assert leg1.designated_location == "loc1"
      assert leg1.exempt_code == -1

      assert leg2.con_id == 200_002
      assert leg2.action == "SELL"
      assert leg2.open_close == 2
      assert leg2.short_sales_slot == 1
      assert leg2.exempt_code == 0
    end

    test "converts delta_neutral_contract" do
      contract = %DomainContract{
        conid: "12345",
        symbol: "SPY",
        delta_neutral_contract: %DomainDeltaNeutral{
          conid: "67890",
          delta: Decimal.new("0.5"),
          price: Decimal.new("100.25")
        }
      }

      proto = ContractMapper.to_proto(contract)

      assert %ProtoDeltaNeutral{} = proto.delta_neutral_contract
      assert proto.delta_neutral_contract.con_id == 67_890
      assert_in_delta proto.delta_neutral_contract.delta, 0.5, 0.0001
      assert_in_delta proto.delta_neutral_contract.price, 100.25, 0.0001
    end

    test "handles nil delta_neutral_contract" do
      contract = %DomainContract{conid: "12345", delta_neutral_contract: nil}
      proto = ContractMapper.to_proto(contract)
      assert proto.delta_neutral_contract == nil
    end

    test "handles empty combo_legs" do
      contract = %DomainContract{conid: "12345", combo_legs: []}
      proto = ContractMapper.to_proto(contract)
      assert proto.combo_legs == []
    end

    test "handles default contract values" do
      contract = %DomainContract{}
      proto = ContractMapper.to_proto(contract)

      assert proto.con_id == 0
      assert proto.symbol == nil
      assert proto.exchange == "SMART"
      assert proto.strike == 0.0
      assert proto.include_expired == nil
    end
  end

  describe "from_proto/1" do
    test "converts all scalar fields back to domain types" do
      proto = %ProtoContract{
        con_id: 265_598,
        symbol: "AAPL",
        sec_type: "STK",
        last_trade_date_or_contract_month: "20240119",
        strike: 150.0,
        right: "C",
        multiplier: 100.0,
        exchange: "SMART",
        primary_exch: "NASDAQ",
        currency: "USD",
        local_symbol: "AAPL",
        trading_class: "NMS",
        sec_id_type: "CUSIP",
        sec_id: "037833100",
        description: "Apple Inc",
        issuer_id: "ISID123",
        include_expired: true
      }

      domain = ContractMapper.from_proto(proto)

      assert %DomainContract{} = domain
      assert domain.conid == "265598"
      assert domain.symbol == "AAPL"
      assert domain.security_type == "STK"
      assert domain.last_trade_date_or_contract_month == "20240119"
      assert domain.strike == "150.0"
      assert domain.right == "C"
      assert domain.multiplier == "100.0"
      assert domain.exchange == "SMART"
      assert domain.primary_exchange == "NASDAQ"
      assert domain.currency == "USD"
      assert domain.local_symbol == "AAPL"
      assert domain.trading_class == "NMS"
      assert domain.security_id_type == "CUSIP"
      assert domain.security_id == "037833100"
      assert domain.description == "Apple Inc"
      assert domain.issuer_id == "ISID123"
      assert domain.include_expired == true
    end

    test "converts combo_legs from proto" do
      proto = %ProtoContract{
        con_id: 100_000,
        combo_legs: [
          %ProtoComboLeg{
            con_id: 200_001,
            ratio: 1,
            action: "BUY",
            exchange: "SMART",
            open_close: 0,
            short_sales_slot: 0,
            exempt_code: -1
          }
        ]
      }

      domain = ContractMapper.from_proto(proto)

      assert length(domain.combo_legs) == 1
      [leg] = domain.combo_legs

      assert %DomainComboLeg{} = leg
      assert leg.conid == 200_001
      assert leg.ratio == 1
      assert leg.action == "BUY"
      assert leg.exchange == "SMART"
      assert leg.open_close == 0
      assert leg.short_sale_slot == 0
      assert leg.exempt_code == -1
    end

    test "converts delta_neutral_contract from proto" do
      proto = %ProtoContract{
        con_id: 12_345,
        delta_neutral_contract: %ProtoDeltaNeutral{
          con_id: 67_890,
          delta: 0.5,
          price: 100.25
        }
      }

      domain = ContractMapper.from_proto(proto)

      assert %DomainDeltaNeutral{} = domain.delta_neutral_contract
      assert domain.delta_neutral_contract.conid == "67890"
      assert Decimal.equal?(domain.delta_neutral_contract.delta, Decimal.from_float(0.5))
      assert Decimal.equal?(domain.delta_neutral_contract.price, Decimal.from_float(100.25))
    end

    test "handles nil fields gracefully" do
      proto = %ProtoContract{con_id: 12_345}
      domain = ContractMapper.from_proto(proto)

      assert domain.conid == "12345"
      assert domain.symbol == ""
      assert domain.security_type == ""
      assert domain.exchange == "SMART"
      assert domain.strike == "0.0"
      assert domain.delta_neutral_contract == nil
      assert domain.combo_legs == []
    end
  end

  describe "roundtrip fidelity" do
    test "Contract roundtrip preserves all field values" do
      original = %DomainContract{
        conid: "265598",
        symbol: "AAPL",
        security_type: "STK",
        last_trade_date_or_contract_month: "20240119",
        strike: "150.0",
        right: "C",
        multiplier: "100",
        exchange: "SMART",
        primary_exchange: "NASDAQ",
        currency: "USD",
        local_symbol: "AAPL",
        trading_class: "NMS",
        security_id_type: "CUSIP",
        security_id: "037833100",
        description: "Apple Inc",
        issuer_id: "ISID123",
        include_expired: false,
        combo_legs_description: "leg_desc",
        combo_legs: [],
        delta_neutral_contract: nil
      }

      roundtripped =
        original
        |> Mapper.to_proto()
        |> Mapper.from_proto()

      assert roundtripped.conid == original.conid
      assert roundtripped.symbol == original.symbol
      assert roundtripped.security_type == original.security_type
      assert roundtripped.last_trade_date_or_contract_month == original.last_trade_date_or_contract_month
      assert roundtripped.right == original.right
      assert roundtripped.exchange == original.exchange
      assert roundtripped.primary_exchange == original.primary_exchange
      assert roundtripped.currency == original.currency
      assert roundtripped.local_symbol == original.local_symbol
      assert roundtripped.trading_class == original.trading_class
      assert roundtripped.security_id_type == original.security_id_type
      assert roundtripped.security_id == original.security_id
      assert roundtripped.description == original.description
      assert roundtripped.issuer_id == original.issuer_id
      assert roundtripped.include_expired == original.include_expired
      assert roundtripped.combo_legs_description == original.combo_legs_description
      assert roundtripped.combo_legs == original.combo_legs
      assert roundtripped.delta_neutral_contract == original.delta_neutral_contract
    end

    test "Contract with combo_legs roundtrips correctly" do
      original = %DomainContract{
        conid: "100000",
        symbol: "SPY",
        security_type: "BAG",
        combo_legs: [
          %DomainComboLeg{
            conid: 200_001,
            ratio: 1,
            action: "BUY",
            exchange: "SMART",
            open_close: 0,
            short_sale_slot: 0,
            designated_location: nil,
            exempt_code: -1
          }
        ]
      }

      roundtripped =
        original
        |> Mapper.to_proto()
        |> Mapper.from_proto()

      assert length(roundtripped.combo_legs) == 1
      [leg] = roundtripped.combo_legs
      [orig_leg] = original.combo_legs

      assert leg.conid == orig_leg.conid
      assert leg.ratio == orig_leg.ratio
      assert leg.action == orig_leg.action
      assert leg.exchange == orig_leg.exchange
      assert leg.open_close == orig_leg.open_close
      assert leg.short_sale_slot == orig_leg.short_sale_slot
      assert leg.exempt_code == orig_leg.exempt_code
    end

    test "Contract with delta_neutral roundtrips correctly" do
      original = %DomainContract{
        conid: "12345",
        symbol: "SPY",
        delta_neutral_contract: %DomainDeltaNeutral{
          conid: "67890",
          delta: Decimal.new("0.5"),
          price: Decimal.new("100")
        }
      }

      roundtripped =
        original
        |> Mapper.to_proto()
        |> Mapper.from_proto()

      assert roundtripped.delta_neutral_contract.conid == "67890"
      # Decimal -> float -> Decimal may lose precision, so use approximate comparison
      assert Decimal.equal?(
               Decimal.round(roundtripped.delta_neutral_contract.delta, 4),
               Decimal.round(original.delta_neutral_contract.delta, 4)
             )
    end
  end
end
