defmodule IbEx.Client.Proto.Protobuf.AutoOpenOrdersRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AutoOpenOrdersRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:auto_bind, 1, json_name: "autoBind", proto3_optional: true, type: :bool)
end
