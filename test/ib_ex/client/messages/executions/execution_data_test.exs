defmodule IbEx.Client.Messages.Executions.ExecutionDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Executions.ExecutionData
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.Execution

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      contract = %Contract{
        conid: "520512263",
        symbol: "GTLB",
        security_type: "STK",
        exchange: "ISLAND",
        currency: "USD",
        local_symbol: "GTLB"
      }

      execution = %Execution{
        execution_id: "00025b44.656e0e0c.01.01",
        timestamp: ~U[2023-12-04 21:39:34Z],
        account_id: "DU3494644",
        exchange: "ISLAND",
        side: "BOT",
        size: 100.0,
        price: 61.54,
        perm_id: 727_593_489,
        client_id: 0,
        order_id: "0",
        liquidation: 0,
        cumulative_quantity: Decimal.new("1600"),
        average_price: 61.496875,
        order_ref: "MktDepth",
        last_liquidity: :add,
        pending_price_revision: false
      }

      msg = %ExecutionData{request_id: "1", contract: contract, execution: execution}

      assert Traceable.to_s(msg) ==
               """
               <-- ExecutionData{
                 request_id: 1,
                 contract: #{inspect(msg.contract)},
                 execution: #{inspect(msg.execution)}
               }
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      msg = %ExecutionData{request_id: "1", contract: %Contract{}, execution: %Execution{}}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
