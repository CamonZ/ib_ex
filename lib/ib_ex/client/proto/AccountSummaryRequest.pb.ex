defmodule IbEx.Client.Proto.Protobuf.AccountSummaryRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AccountSummaryRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:group, 2, proto3_optional: true, type: :string)
  field(:tags, 3, proto3_optional: true, type: :string)
end
