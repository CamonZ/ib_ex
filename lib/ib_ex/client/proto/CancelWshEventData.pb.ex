defmodule IbEx.Client.Proto.Protobuf.CancelWshEventData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CancelWshEventData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
end
