defmodule IbEx.Client.Proto.Protobuf.WshEventData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.WshEventData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:data_json, 2, json_name: "dataJson", proto3_optional: true, type: :string)
end
