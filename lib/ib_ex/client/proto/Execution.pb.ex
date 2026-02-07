defmodule IbEx.Client.Proto.Protobuf.Execution do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.Execution",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:order_id, 1, json_name: "orderId", proto3_optional: true, type: :int32)
  field(:exec_id, 2, json_name: "execId", proto3_optional: true, type: :string)
  field(:time, 3, proto3_optional: true, type: :string)
  field(:acct_number, 4, json_name: "acctNumber", proto3_optional: true, type: :string)
  field(:exchange, 5, proto3_optional: true, type: :string)
  field(:side, 6, proto3_optional: true, type: :string)
  field(:shares, 7, proto3_optional: true, type: :string)
  field(:price, 8, proto3_optional: true, type: :double)
  field(:perm_id, 9, json_name: "permId", proto3_optional: true, type: :int64)
  field(:client_id, 10, json_name: "clientId", proto3_optional: true, type: :int32)
  field(:is_liquidation, 11, json_name: "isLiquidation", proto3_optional: true, type: :bool)
  field(:cum_qty, 12, json_name: "cumQty", proto3_optional: true, type: :string)
  field(:avg_price, 13, json_name: "avgPrice", proto3_optional: true, type: :double)
  field(:order_ref, 14, json_name: "orderRef", proto3_optional: true, type: :string)
  field(:ev_rule, 15, json_name: "evRule", proto3_optional: true, type: :string)
  field(:ev_multiplier, 16, json_name: "evMultiplier", proto3_optional: true, type: :double)
  field(:model_code, 17, json_name: "modelCode", proto3_optional: true, type: :string)
  field(:last_liquidity, 18, json_name: "lastLiquidity", proto3_optional: true, type: :int32)
  field(:is_price_revision_pending, 19, json_name: "isPriceRevisionPending", proto3_optional: true, type: :bool)
  field(:submitter, 20, proto3_optional: true, type: :string)
  field(:opt_exercise_or_lapse_type, 21, json_name: "optExerciseOrLapseType", proto3_optional: true, type: :int32)
end
