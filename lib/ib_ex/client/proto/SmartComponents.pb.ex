defmodule IbEx.Client.Proto.Protobuf.SmartComponents do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SmartComponents",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:smart_components, 2,
    json_name: "smartComponents",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.SmartComponent
  )
end
