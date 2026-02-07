defmodule IbEx.Client.Proto.Protobuf.CancelMarketDepth do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CancelMarketDepth",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:is_smart_depth, 2, json_name: "isSmartDepth", proto3_optional: true, type: :bool)
end
