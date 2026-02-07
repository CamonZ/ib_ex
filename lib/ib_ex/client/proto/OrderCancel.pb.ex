defmodule IbEx.Client.Proto.Protobuf.OrderCancel do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrderCancel",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:manual_order_cancel_time, 1, json_name: "manualOrderCancelTime", proto3_optional: true, type: :string)
  field(:ext_operator, 2, json_name: "extOperator", proto3_optional: true, type: :string)
  field(:manual_order_indicator, 3, json_name: "manualOrderIndicator", proto3_optional: true, type: :int32)
end
