defmodule IbEx.Client.Proto.MapperTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Mapper

  alias IbEx.Client.Types.Contract, as: DomainContract
  alias IbEx.Client.Types.Order, as: DomainOrder
  alias IbEx.Client.Types.Execution, as: DomainExecution
  alias IbEx.Client.Types.ExecutionsFilter, as: DomainExecutionsFilter

  alias IbEx.Client.Proto.Protobuf.Contract, as: ProtoContract
  alias IbEx.Client.Proto.Protobuf.Order, as: ProtoOrder
  alias IbEx.Client.Proto.Protobuf.Execution, as: ProtoExecution
  alias IbEx.Client.Proto.Protobuf.ExecutionFilter, as: ProtoExecutionFilter

  describe "to_proto/1 dispatches correctly" do
    test "dispatches Contract" do
      domain = %DomainContract{conid: "265598", symbol: "AAPL"}
      result = Mapper.to_proto(domain)
      assert %ProtoContract{} = result
      assert result.con_id == 265_598
      assert result.symbol == "AAPL"
    end

    test "dispatches Order" do
      domain = DomainOrder.new(%{action: "BUY", total_quantity: 100, order_type: "LMT"})
      result = Mapper.to_proto(domain)
      assert %ProtoOrder{} = result
      assert result.action == "BUY"
      assert result.total_quantity == "100"
      assert result.order_type == "LMT"
    end

    test "dispatches Execution" do
      domain = %DomainExecution{execution_id: "0001", exchange: "SMART"}
      result = Mapper.to_proto(domain)
      assert %ProtoExecution{} = result
      assert result.exec_id == "0001"
      assert result.exchange == "SMART"
    end

    test "dispatches ExecutionsFilter" do
      {:ok, domain} = DomainExecutionsFilter.new(symbol: "AAPL", side: "BUY")
      result = Mapper.to_proto(domain)
      assert %ProtoExecutionFilter{} = result
      assert result.symbol == "AAPL"
      assert result.side == "BUY"
    end

    test "raises ArgumentError for unknown struct type" do
      assert_raise ArgumentError, ~r/No proto mapping registered/, fn ->
        Mapper.to_proto(%URI{})
      end
    end
  end

  describe "from_proto/1 dispatches correctly" do
    test "dispatches Contract" do
      proto = %ProtoContract{con_id: 265_598, symbol: "AAPL"}
      result = Mapper.from_proto(proto)
      assert %DomainContract{} = result
      assert result.conid == "265598"
      assert result.symbol == "AAPL"
    end

    test "dispatches Order" do
      proto = %ProtoOrder{action: "BUY", total_quantity: "100", order_type: "LMT"}
      result = Mapper.from_proto(proto)
      assert %DomainOrder{} = result
      assert result.action == "BUY"
      assert result.total_quantity == 100
      assert result.order_type == "LMT"
    end

    test "dispatches Execution" do
      proto = %ProtoExecution{exec_id: "0001", exchange: "SMART"}
      result = Mapper.from_proto(proto)
      assert %DomainExecution{} = result
      assert result.execution_id == "0001"
      assert result.exchange == "SMART"
    end

    test "dispatches ExecutionFilter" do
      proto = %ProtoExecutionFilter{symbol: "AAPL", side: "BUY"}
      result = Mapper.from_proto(proto)
      assert %DomainExecutionsFilter{} = result
      assert result.symbol == "AAPL"
      assert result.side == "BUY"
    end

    test "raises ArgumentError for unknown proto struct type" do
      assert_raise ArgumentError, ~r/No domain mapping registered/, fn ->
        Mapper.from_proto(%IbEx.Client.Proto.Protobuf.ManagedAccounts{})
      end
    end
  end
end
