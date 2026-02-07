defmodule IbEx.Client.Proto.Protobuf.AttachedOrders do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AttachedOrders",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:sl_order_id, 1, json_name: "slOrderId", proto3_optional: true, type: :int32)
  field(:sl_order_type, 2, json_name: "slOrderType", proto3_optional: true, type: :string)
  field(:pt_order_id, 3, json_name: "ptOrderId", proto3_optional: true, type: :int32)
  field(:pt_order_type, 4, json_name: "ptOrderType", proto3_optional: true, type: :string)
end
