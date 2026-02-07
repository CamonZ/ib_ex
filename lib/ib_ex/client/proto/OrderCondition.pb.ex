defmodule IbEx.Client.Proto.Protobuf.OrderCondition do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrderCondition",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:type, 1, proto3_optional: true, type: :int32)
  field(:is_conjunction_connection, 2, json_name: "isConjunctionConnection", proto3_optional: true, type: :bool)
  field(:is_more, 3, json_name: "isMore", proto3_optional: true, type: :bool)
  field(:con_id, 4, json_name: "conId", proto3_optional: true, type: :int32)
  field(:exchange, 5, proto3_optional: true, type: :string)
  field(:symbol, 6, proto3_optional: true, type: :string)
  field(:sec_type, 7, json_name: "secType", proto3_optional: true, type: :string)
  field(:percent, 8, proto3_optional: true, type: :int32)
  field(:change_percent, 9, json_name: "changePercent", proto3_optional: true, type: :double)
  field(:price, 10, proto3_optional: true, type: :double)
  field(:trigger_method, 11, json_name: "triggerMethod", proto3_optional: true, type: :int32)
  field(:time, 12, proto3_optional: true, type: :string)
  field(:volume, 13, proto3_optional: true, type: :int32)
end
