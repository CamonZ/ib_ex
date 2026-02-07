defmodule IbEx.Client.Proto.Protobuf.PnLSingleRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.PnLSingleRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:account, 2, proto3_optional: true, type: :string)
  field(:model_code, 3, json_name: "modelCode", proto3_optional: true, type: :string)
  field(:con_id, 4, json_name: "conId", proto3_optional: true, type: :int32)
end
