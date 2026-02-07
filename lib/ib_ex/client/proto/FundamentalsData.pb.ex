defmodule IbEx.Client.Proto.Protobuf.FundamentalsData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.FundamentalsData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:data, 2, proto3_optional: true, type: :string)
end
