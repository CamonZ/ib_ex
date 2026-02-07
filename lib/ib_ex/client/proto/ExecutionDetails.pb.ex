defmodule IbEx.Client.Proto.Protobuf.ExecutionDetails do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ExecutionDetails",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:execution, 3, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Execution)
end
