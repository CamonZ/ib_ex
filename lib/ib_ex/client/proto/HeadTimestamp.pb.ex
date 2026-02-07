defmodule IbEx.Client.Proto.Protobuf.HeadTimestamp do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HeadTimestamp",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:head_timestamp, 2, json_name: "headTimestamp", proto3_optional: true, type: :string)
end
