defmodule IbEx.Client.Proto.Protobuf.TickReqParams do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickReqParams",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:min_tick, 2, json_name: "minTick", proto3_optional: true, type: :string)
  field(:bbo_exchange, 3, json_name: "bboExchange", proto3_optional: true, type: :string)
  field(:snapshot_permissions, 4, json_name: "snapshotPermissions", proto3_optional: true, type: :int32)
end
