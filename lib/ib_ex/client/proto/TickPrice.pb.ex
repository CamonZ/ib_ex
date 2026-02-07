defmodule IbEx.Client.Proto.Protobuf.TickPrice do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickPrice",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:tick_type, 2, json_name: "tickType", proto3_optional: true, type: :int32)
  field(:price, 3, proto3_optional: true, type: :double)
  field(:size, 4, proto3_optional: true, type: :string)
  field(:attr_mask, 5, json_name: "attrMask", proto3_optional: true, type: :int32)
end
