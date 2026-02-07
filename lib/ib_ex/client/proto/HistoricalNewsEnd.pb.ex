defmodule IbEx.Client.Proto.Protobuf.HistoricalNewsEnd do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalNewsEnd",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:has_more, 2, json_name: "hasMore", proto3_optional: true, type: :bool)
end
