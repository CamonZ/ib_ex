defmodule IbEx.Client.Proto.Protobuf.SymbolSamples do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SymbolSamples",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:contract_descriptions, 2,
    json_name: "contractDescriptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.ContractDescription
  )
end
