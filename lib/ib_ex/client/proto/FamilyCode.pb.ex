defmodule IbEx.Client.Proto.Protobuf.FamilyCode do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.FamilyCode",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:account_id, 1, json_name: "accountId", proto3_optional: true, type: :string)
  field(:family_code, 2, json_name: "familyCode", proto3_optional: true, type: :string)
end
