defmodule IbEx.Client.Proto.Protobuf.ExecutionRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ExecutionRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:execution_filter, 2,
    json_name: "executionFilter",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.ExecutionFilter
  )
end
