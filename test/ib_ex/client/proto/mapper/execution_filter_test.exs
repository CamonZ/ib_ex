defmodule IbEx.Client.Proto.Mapper.ExecutionFilterTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Mapper.ExecutionFilter, as: FilterMapper

  alias IbEx.Client.Types.ExecutionsFilter, as: DomainFilter
  alias IbEx.Client.Proto.Protobuf.ExecutionFilter, as: ProtoFilter

  describe "to_proto/1" do
    test "converts all fields correctly" do
      {:ok, filter} =
        DomainFilter.new(
          client_id: "1",
          account_id: "DU12345",
          time: "20240115-10:30:00",
          symbol: "AAPL",
          security_type: "STK",
          exchange: "SMART",
          side: "BUY",
          last_n_days: 7,
          specific_dates: ["20240108", "20240109"]
        )

      proto = FilterMapper.to_proto(filter)

      assert %ProtoFilter{} = proto
      assert proto.client_id == 1
      assert proto.acct_code == "DU12345"
      assert proto.time == "20240115-10:30:00"
      assert proto.symbol == "AAPL"
      assert proto.sec_type == "STK"
      assert proto.exchange == "SMART"
      assert proto.side == "BUY"
      assert proto.last_n_days == 7
      assert proto.specific_dates == [20_240_108, 20_240_109]
    end

    test "handles nil fields" do
      {:ok, filter} = DomainFilter.new(symbol: "AAPL")
      proto = FilterMapper.to_proto(filter)

      assert proto.client_id == nil
      assert proto.acct_code == nil
      assert proto.time == nil
      assert proto.symbol == "AAPL"
      assert proto.sec_type == nil
      assert proto.exchange == nil
      assert proto.side == nil
      assert proto.specific_dates == []
    end
  end

  describe "from_proto/1" do
    test "converts all fields back to domain types" do
      proto = %ProtoFilter{
        client_id: 1,
        acct_code: "DU12345",
        time: "20240115-10:30:00",
        symbol: "AAPL",
        sec_type: "STK",
        exchange: "SMART",
        side: "BUY",
        last_n_days: 7,
        specific_dates: [20_240_108, 20_240_109]
      }

      filter = FilterMapper.from_proto(proto)

      assert %DomainFilter{} = filter
      assert filter.client_id == "1"
      assert filter.account_id == "DU12345"
      assert filter.time == "20240115-10:30:00"
      assert filter.symbol == "AAPL"
      assert filter.security_type == "STK"
      assert filter.exchange == "SMART"
      assert filter.side == "BUY"
      assert filter.last_n_days == 7
      assert filter.specific_dates == ["20240108", "20240109"]
    end

    test "handles nil fields" do
      proto = %ProtoFilter{symbol: "AAPL"}
      filter = FilterMapper.from_proto(proto)

      assert filter.client_id == nil
      assert filter.account_id == nil
      assert filter.time == nil
      assert filter.symbol == "AAPL"
      assert filter.security_type == nil
    end
  end

  describe "roundtrip fidelity" do
    test "ExecutionsFilter roundtrips preserving all fields" do
      {:ok, original} =
        DomainFilter.new(
          client_id: "1",
          account_id: "DU12345",
          time: "20240115-10:30:00",
          symbol: "AAPL",
          security_type: "STK",
          exchange: "SMART",
          side: "BUY",
          last_n_days: 7
        )

      roundtripped =
        original
        |> Mapper.to_proto()
        |> Mapper.from_proto()

      assert roundtripped.client_id == original.client_id
      assert roundtripped.account_id == original.account_id
      assert roundtripped.time == original.time
      assert roundtripped.symbol == original.symbol
      assert roundtripped.security_type == original.security_type
      assert roundtripped.exchange == original.exchange
      assert roundtripped.side == original.side
      assert roundtripped.last_n_days == original.last_n_days
    end
  end
end
