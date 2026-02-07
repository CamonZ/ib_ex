defmodule IbEx.Client.Proto.Protobuf.StartApiRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.StartApiRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:client_id, 1, json_name: "clientId", proto3_optional: true, type: :int32)
  field(:optional_capabilities, 2, json_name: "optionalCapabilities", proto3_optional: true, type: :string)
end
