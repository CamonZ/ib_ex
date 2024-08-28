defmodule IbEx.Client.Messages.Executions.ExecutionDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Contract.DeltaNeutral
  alias IbEx.Client.Messages.Executions.ExecutionData
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.Execution

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  @fields [
    "1",
    "0",
    "520512263",
    "GTLB",
    "STK",
    "",
    "0.0",
    "",
    "",
    "ISLAND",
    "USD",
    "GTLB",
    "",
    "00025b44.656e0e0c.01.01",
    "20231204 22:39:34 Europe/Madrid",
    "DU3494644",
    "ISLAND",
    "BOT",
    "100",
    "61.54",
    "727593489",
    "0",
    "0",
    "1600",
    "61.496875",
    "MktDepth",
    "",
    "",
    "",
    "1",
    "0"
  ]

  describe "from_fields/1" do
    test "creates an ExecutionData with valid fields" do
      assert {:ok, msg} = ExecutionData.from_fields(@fields)

      assert msg.request_id == "1"

      assert msg.contract == %Contract{
               combo_legs: [],
               combo_legs_description: nil,
               conid: "520512263",
               currency: "USD",
               delta_neutral_contract: nil,
               description: "",
               exchange: "ISLAND",
               include_expired: false,
               issuer_id: "",
               last_trade_date_or_contract_month: "",
               local_symbol: "GTLB",
               multiplier: "",
               primary_exchange: "",
               right: "",
               security_id: "",
               security_id_type: "",
               security_type: "STK",
               strike: "0.0",
               symbol: "GTLB",
               trading_class: ""
             }

      assert msg.execution == %Execution{
               account_id: "DU3494644",
               average_price: 61.496875,
               client_id: 0,
               cumulative_quantity: Decimal.new("1600"),
               ev_multiplier: nil,
               ev_rule: "",
               exchange: "ISLAND",
               execution_id: "00025b44.656e0e0c.01.01",
               last_liquidity: 1,
               liquidation: 0,
               model_code: "",
               order_id: "0",
               order_ref: "MktDepth",
               pending_price_revision: false,
               perm_id: 727_593_489,
               price: 61.54,
               side: "BOT",
               size: 100.0,
               timestamp: ~U[2023-12-04 21:39:34Z]
             }
    end

    test "returns an error with invalid fields" do
      invalid_fields = ["invalid", "fields"]
      assert {:error, :invalid_args} == ExecutionData.from_fields(invalid_fields)
    end
  end

  describe "inspect/2" do
    test "returns a human-readable version of the message" do
      {:ok, msg} = ExecutionData.from_fields(@fields)

      assert inspect(msg) ==
               """
               <-- ExecutionData{
                 request_id: 1,
                 contract: %IbEx.Client.Types.Contract{conid: "520512263", symbol: "GTLB", security_type: "STK", last_trade_date_or_contract_month: "", strike: "0.0", right: "", multiplier: "", exchange: "ISLAND", currency: "USD", local_symbol: "GTLB", primary_exchange: "", trading_class: "", include_expired: false, security_id_type: "", security_id: "", combo_legs_description: nil, combo_legs: [], delta_neutral_contract: nil, description: "", issuer_id: ""},
                 execution: %IbEx.Client.Types.Execution{execution_id: "00025b44.656e0e0c.01.01", timestamp: ~U[2023-12-04 21:39:34Z], account_id: "DU3494644", exchange: "ISLAND", side: "BOT", size: 100.0, price: 61.54, perm_id: 727593489, client_id: 0, order_id: "0", liquidation: 0, cumulative_quantity: Decimal.new("1600"), average_price: 61.496875, order_ref: "MktDepth", ev_rule: "", ev_multiplier: nil, model_code: "", last_liquidity: 1, pending_price_revision: false}
               }
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      {:ok, msg} = ExecutionData.from_fields(@fields)

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
