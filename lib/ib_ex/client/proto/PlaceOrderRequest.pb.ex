defmodule IbEx.Client.Proto.Protobuf.PlaceOrderRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.PlaceOrderRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:order_id, 1, json_name: "orderId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:order, 3, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Order)

  field(:attached_orders, 4,
    json_name: "attachedOrders",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.AttachedOrders
  )
end
