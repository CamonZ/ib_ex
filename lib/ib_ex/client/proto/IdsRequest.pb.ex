defmodule IbEx.Client.Proto.Protobuf.IdsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.IdsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:num_ids, 1, json_name: "numIds", proto3_optional: true, type: :int32)
end
