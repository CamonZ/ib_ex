defmodule IbEx.Client.Proto.Protobuf.VerifyCompleted do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.VerifyCompleted",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:is_successful, 1, json_name: "isSuccessful", proto3_optional: true, type: :bool)
  field(:error_text, 2, json_name: "errorText", proto3_optional: true, type: :string)
end
