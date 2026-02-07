defmodule IbEx.Client.Proto.Protobuf.AccountSummary do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AccountSummary",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:account, 2, proto3_optional: true, type: :string)
  field(:tag, 3, proto3_optional: true, type: :string)
  field(:value, 4, proto3_optional: true, type: :string)
  field(:currency, 5, proto3_optional: true, type: :string)
end
