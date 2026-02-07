defmodule IbEx.Client.Proto.Protobuf.CancelOrderRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CancelOrderRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:order_id, 1, json_name: "orderId", proto3_optional: true, type: :int32)
  field(:order_cancel, 2, json_name: "orderCancel", proto3_optional: true, type: IbEx.Client.Proto.Protobuf.OrderCancel)
end
