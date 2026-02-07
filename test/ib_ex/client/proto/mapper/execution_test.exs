defmodule IbEx.Client.Proto.Mapper.ExecutionTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Mapper.Execution, as: ExecutionMapper

  alias IbEx.Client.Types.Execution, as: DomainExecution
  alias IbEx.Client.Proto.Protobuf.Execution, as: ProtoExecution

  describe "to_proto/1" do
    test "converts all fields correctly" do
      exec = %DomainExecution{
        order_id: 42,
        execution_id: "0001e0bef1.67890abc.01.01",
        timestamp: "20240115 10:30:00",
        account_id: "DU12345",
        exchange: "SMART",
        side: "BOT",
        size: 100.0,
        price: 150.50,
        perm_id: 987_654,
        client_id: 1,
        liquidation: 0,
        cumulative_quantity: Decimal.new("100"),
        average_price: 150.50,
        order_ref: "ref1",
        ev_rule: "rule1",
        ev_multiplier: Decimal.new("1.0"),
        model_code: "model1",
        last_liquidity: 1,
        pending_price_revision: false,
        submitter: "user1",
        opt_exercise_or_lapse_type: :exercise
      }

      proto = ExecutionMapper.to_proto(exec)

      assert %ProtoExecution{} = proto
      assert proto.order_id == 42
      assert proto.exec_id == "0001e0bef1.67890abc.01.01"
      assert proto.time == "20240115 10:30:00"
      assert proto.acct_number == "DU12345"
      assert proto.exchange == "SMART"
      assert proto.side == "BOT"
      assert proto.shares == "100.0"
      assert proto.price == 150.50
      assert proto.perm_id == 987_654
      assert proto.client_id == 1
      assert proto.is_liquidation == false
      assert proto.cum_qty == "100"
      assert proto.avg_price == 150.50
      assert proto.order_ref == "ref1"
      assert proto.ev_rule == "rule1"
      assert_in_delta proto.ev_multiplier, 1.0, 0.001
      assert proto.model_code == "model1"
      assert proto.last_liquidity == 1
      assert proto.is_price_revision_pending == false
      assert proto.submitter == "user1"
      assert proto.opt_exercise_or_lapse_type == 1
    end

    test "converts liquidation != 0 to is_liquidation true" do
      exec = %DomainExecution{liquidation: 1}
      proto = ExecutionMapper.to_proto(exec)
      assert proto.is_liquidation == true
    end

    test "converts opt_exercise_or_lapse_type atoms" do
      assert ExecutionMapper.to_proto(%DomainExecution{opt_exercise_or_lapse_type: :none}).opt_exercise_or_lapse_type ==
               0

      assert ExecutionMapper.to_proto(%DomainExecution{opt_exercise_or_lapse_type: :exercise}).opt_exercise_or_lapse_type ==
               1

      assert ExecutionMapper.to_proto(%DomainExecution{opt_exercise_or_lapse_type: :lapse}).opt_exercise_or_lapse_type ==
               2

      assert ExecutionMapper.to_proto(%DomainExecution{opt_exercise_or_lapse_type: nil}).opt_exercise_or_lapse_type ==
               nil
    end
  end

  describe "from_proto/1" do
    test "converts all fields back to domain types" do
      proto = %ProtoExecution{
        order_id: 42,
        exec_id: "0001e0bef1.67890abc.01.01",
        time: "20240115 10:30:00",
        acct_number: "DU12345",
        exchange: "SMART",
        side: "BOT",
        shares: "100.0",
        price: 150.50,
        perm_id: 987_654,
        client_id: 1,
        is_liquidation: false,
        cum_qty: "100",
        avg_price: 150.50,
        order_ref: "ref1",
        ev_rule: "rule1",
        ev_multiplier: 1.0,
        model_code: "model1",
        last_liquidity: 1,
        is_price_revision_pending: false,
        submitter: "user1",
        opt_exercise_or_lapse_type: 1
      }

      exec = ExecutionMapper.from_proto(proto)

      assert %DomainExecution{} = exec
      assert exec.order_id == 42
      assert exec.execution_id == "0001e0bef1.67890abc.01.01"
      assert exec.timestamp == "20240115 10:30:00"
      assert exec.account_id == "DU12345"
      assert exec.exchange == "SMART"
      assert exec.side == "BOT"
      assert exec.size == 100.0
      assert exec.price == 150.50
      assert exec.perm_id == 987_654
      assert exec.client_id == 1
      assert exec.liquidation == 0
      assert Decimal.equal?(exec.cumulative_quantity, Decimal.new("100"))
      assert exec.average_price == 150.50
      assert exec.order_ref == "ref1"
      assert exec.ev_rule == "rule1"
      assert Decimal.equal?(Decimal.round(exec.ev_multiplier, 1), Decimal.new("1.0"))
      assert exec.model_code == "model1"
      assert exec.last_liquidity == 1
      assert exec.pending_price_revision == false
      assert exec.submitter == "user1"
      assert exec.opt_exercise_or_lapse_type == :exercise
    end

    test "converts is_liquidation true to liquidation 1" do
      proto = %ProtoExecution{is_liquidation: true}
      exec = ExecutionMapper.from_proto(proto)
      assert exec.liquidation == 1
    end

    test "handles nil fields with defaults" do
      proto = %ProtoExecution{order_id: 1}
      exec = ExecutionMapper.from_proto(proto)

      assert exec.execution_id == ""
      assert exec.exchange == ""
      assert exec.side == ""
      assert exec.size == 0
      assert exec.price == 0.0
      assert exec.perm_id == 0
      assert exec.client_id == 0
      assert exec.liquidation == 0
    end
  end

  describe "roundtrip fidelity" do
    test "Execution roundtrips preserving key fields" do
      original = %DomainExecution{
        order_id: 42,
        execution_id: "exec123",
        timestamp: "20240115 10:30:00",
        account_id: "DU12345",
        exchange: "SMART",
        side: "BOT",
        size: 100.0,
        price: 150.50,
        perm_id: 987_654,
        client_id: 1,
        liquidation: 0,
        cumulative_quantity: Decimal.new("100"),
        average_price: 150.50,
        order_ref: "ref1",
        ev_rule: "rule1",
        ev_multiplier: Decimal.new("0"),
        model_code: "model1",
        last_liquidity: 1,
        pending_price_revision: false,
        submitter: "user1",
        opt_exercise_or_lapse_type: :exercise
      }

      roundtripped =
        original
        |> Mapper.to_proto()
        |> Mapper.from_proto()

      assert roundtripped.order_id == original.order_id
      assert roundtripped.execution_id == original.execution_id
      assert roundtripped.timestamp == original.timestamp
      assert roundtripped.account_id == original.account_id
      assert roundtripped.exchange == original.exchange
      assert roundtripped.side == original.side
      assert roundtripped.price == original.price
      assert roundtripped.perm_id == original.perm_id
      assert roundtripped.client_id == original.client_id
      assert roundtripped.liquidation == original.liquidation
      assert roundtripped.average_price == original.average_price
      assert roundtripped.order_ref == original.order_ref
      assert roundtripped.model_code == original.model_code
      assert roundtripped.last_liquidity == original.last_liquidity
      assert roundtripped.pending_price_revision == original.pending_price_revision
      assert roundtripped.submitter == original.submitter
      assert roundtripped.opt_exercise_or_lapse_type == original.opt_exercise_or_lapse_type
    end
  end
end
