defmodule IbEx.Client.Proto.Protobuf.OrdersConfig do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrdersConfig",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:smart_routing, 1, json_name: "smartRouting", type: IbEx.Client.Proto.Protobuf.OrdersSmartRoutingConfig)
end
