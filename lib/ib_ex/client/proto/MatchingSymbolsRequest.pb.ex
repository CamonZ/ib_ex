defmodule IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MatchingSymbolsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:pattern, 2, proto3_optional: true, type: :string)
end
