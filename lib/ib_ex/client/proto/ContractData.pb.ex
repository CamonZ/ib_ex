defmodule IbEx.Client.Proto.Protobuf.ContractData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ContractData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)

  field(:contract_details, 3,
    json_name: "contractDetails",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.ContractDetails
  )
end
