defmodule IbEx.Client.Proto.Protobuf.UpdateDisplayGroupRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.UpdateDisplayGroupRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract_info, 2, json_name: "contractInfo", proto3_optional: true, type: :string)
end
