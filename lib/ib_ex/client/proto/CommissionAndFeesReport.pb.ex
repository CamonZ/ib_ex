defmodule IbEx.Client.Proto.Protobuf.CommissionAndFeesReport do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CommissionAndFeesReport",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:exec_id, 1, json_name: "execId", proto3_optional: true, type: :string)
  field(:commission_and_fees, 2, json_name: "commissionAndFees", proto3_optional: true, type: :double)
  field(:currency, 3, proto3_optional: true, type: :string)
  field(:realized_pnl, 4, json_name: "realizedPNL", proto3_optional: true, type: :double)
  field(:bond_yield, 5, json_name: "bondYield", proto3_optional: true, type: :double)
  field(:yield_redemption_date, 6, json_name: "yieldRedemptionDate", proto3_optional: true, type: :string)
end
