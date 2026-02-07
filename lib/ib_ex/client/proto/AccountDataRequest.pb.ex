defmodule IbEx.Client.Proto.Protobuf.AccountDataRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AccountDataRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:subscribe, 1, proto3_optional: true, type: :bool)
  field(:acct_code, 2, json_name: "acctCode", proto3_optional: true, type: :string)
end
