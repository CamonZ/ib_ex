defmodule IbEx.Client.Proto.Protobuf.CompletedOrder do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CompletedOrder",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:contract, 1, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:order, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Order)
  field(:order_state, 3, json_name: "orderState", proto3_optional: true, type: IbEx.Client.Proto.Protobuf.OrderState)
end
