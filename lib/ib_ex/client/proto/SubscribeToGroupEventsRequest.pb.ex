defmodule IbEx.Client.Proto.Protobuf.SubscribeToGroupEventsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SubscribeToGroupEventsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:group_id, 2, json_name: "groupId", proto3_optional: true, type: :int32)
end
