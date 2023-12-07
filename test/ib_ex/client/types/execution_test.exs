defmodule IbEx.Client.Types.ExecutionTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Execution

  describe "from_execution_data/1" do
    test "creates an Execution with valid fields" do
      fields = [
        "order123",
        "exec123",
        "20231204 22:39:34 Europe/Madrid",
        "acc123",
        "NYSE",
        "BUY",
        "100",
        "61.54",
        "727593489",
        "0",
        "0",
        "100",
        "61.54",
        "ref123",
        "rule1",
        "2.0",
        "modelABC",
        "1",
        "0"
      ]

      assert {:ok, execution} = Execution.from_execution_data(fields)

      assert execution.order_id == "order123"
      assert execution.execution_id == "exec123"
      assert execution.timestamp == ~U[2023-12-04 21:39:34Z]
      assert execution.account_id == "acc123"
      assert execution.exchange == "NYSE"
      assert execution.side == "BUY"
      assert execution.size == 100.0
      assert execution.price == 61.54
      assert execution.perm_id == 727_593_489
      assert execution.client_id == 0
      assert execution.liquidation == 0
      assert execution.cumulative_quantity == Decimal.new("100")
      assert execution.average_price == 61.54
      assert execution.order_ref == "ref123"
      assert execution.ev_rule == "rule1"
      assert execution.ev_multiplier == 2.0
      assert execution.model_code == "modelABC"
      assert execution.last_liquidity == 1
      assert execution.pending_price_revision == false
    end

    test "returns an error with invalid timestamp" do
      invalid_fields = List.duplicate("valid", 18) ++ ["invalid-timestamp"]
      assert {:error, :invalid_args} == Execution.from_execution_data(invalid_fields)
    end

    test "returns an error with invalid fields" do
      invalid_fields = List.duplicate("invalid", 19)
      assert {:error, :invalid_args} == Execution.from_execution_data(invalid_fields)
    end
  end
end
