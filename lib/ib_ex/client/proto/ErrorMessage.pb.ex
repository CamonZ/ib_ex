defmodule IbEx.Client.Proto.Protobuf.ErrorMessage do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ErrorMessage",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:id, 1, proto3_optional: true, type: :int32)
  field(:error_time, 2, json_name: "errorTime", proto3_optional: true, type: :int64)
  field(:error_code, 3, json_name: "errorCode", proto3_optional: true, type: :int32)
  field(:error_msg, 4, json_name: "errorMsg", proto3_optional: true, type: :string)
  field(:advanced_order_reject_json, 5, json_name: "advancedOrderRejectJson", proto3_optional: true, type: :string)
end
