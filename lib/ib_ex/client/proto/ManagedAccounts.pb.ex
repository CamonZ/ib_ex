defmodule IbEx.Client.Proto.Protobuf.ManagedAccounts do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ManagedAccounts",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:accounts_list, 1, json_name: "accountsList", proto3_optional: true, type: :string)
end
