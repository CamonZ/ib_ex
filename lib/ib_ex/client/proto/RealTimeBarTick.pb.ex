defmodule IbEx.Client.Proto.Protobuf.RealTimeBarTick do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.RealTimeBarTick",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:time, 2, proto3_optional: true, type: :int64)
  field(:open, 3, proto3_optional: true, type: :double)
  field(:high, 4, proto3_optional: true, type: :double)
  field(:low, 5, proto3_optional: true, type: :double)
  field(:close, 6, proto3_optional: true, type: :double)
  field(:volume, 7, proto3_optional: true, type: :string)
  field(:wap, 8, json_name: "WAP", proto3_optional: true, type: :string)
  field(:count, 9, proto3_optional: true, type: :int32)
end
