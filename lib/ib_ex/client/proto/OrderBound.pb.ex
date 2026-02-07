defmodule IbEx.Client.Proto.Protobuf.OrderBound do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrderBound",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:perm_id, 1, json_name: "permId", proto3_optional: true, type: :int64)
  field(:client_id, 2, json_name: "clientId", proto3_optional: true, type: :int32)
  field(:order_id, 3, json_name: "orderId", proto3_optional: true, type: :int32)
end
