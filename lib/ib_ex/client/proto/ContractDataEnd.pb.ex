defmodule IbEx.Client.Proto.Protobuf.ContractDataEnd do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ContractDataEnd",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
end
