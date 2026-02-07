defmodule IbEx.Client.Proto.Protobuf.ContractDescription do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ContractDescription",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:contract, 1, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:derivative_sec_types, 2, json_name: "derivativeSecTypes", repeated: true, type: :string)
end
