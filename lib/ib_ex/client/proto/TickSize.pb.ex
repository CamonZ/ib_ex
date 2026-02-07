defmodule IbEx.Client.Proto.Protobuf.TickSize do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickSize",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:tick_type, 2, json_name: "tickType", proto3_optional: true, type: :int32)
  field(:size, 3, proto3_optional: true, type: :string)
end
