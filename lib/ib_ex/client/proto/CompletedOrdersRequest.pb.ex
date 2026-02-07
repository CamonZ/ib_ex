defmodule IbEx.Client.Proto.Protobuf.CompletedOrdersRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CompletedOrdersRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:api_only, 1, json_name: "apiOnly", proto3_optional: true, type: :bool)
end
