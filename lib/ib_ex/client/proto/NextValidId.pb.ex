defmodule IbEx.Client.Proto.Protobuf.NextValidId do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NextValidId",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:order_id, 1, json_name: "orderId", proto3_optional: true, type: :int32)
end
