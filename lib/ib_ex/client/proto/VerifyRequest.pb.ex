defmodule IbEx.Client.Proto.Protobuf.VerifyRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.VerifyRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:api_name, 1, json_name: "apiName", proto3_optional: true, type: :string)
  field(:api_version, 2, json_name: "apiVersion", proto3_optional: true, type: :string)
end
