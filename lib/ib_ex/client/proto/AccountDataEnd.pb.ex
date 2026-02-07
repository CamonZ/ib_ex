defmodule IbEx.Client.Proto.Protobuf.AccountDataEnd do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AccountDataEnd",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:account_name, 1, json_name: "accountName", proto3_optional: true, type: :string)
end
