defmodule IbEx.Client.Proto.Protobuf.TickOptionComputation do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickOptionComputation",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:tick_type, 2, json_name: "tickType", proto3_optional: true, type: :int32)
  field(:tick_attrib, 3, json_name: "tickAttrib", proto3_optional: true, type: :int32)
  field(:implied_vol, 4, json_name: "impliedVol", proto3_optional: true, type: :double)
  field(:delta, 5, proto3_optional: true, type: :double)
  field(:opt_price, 6, json_name: "optPrice", proto3_optional: true, type: :double)
  field(:pv_dividend, 7, json_name: "pvDividend", proto3_optional: true, type: :double)
  field(:gamma, 8, proto3_optional: true, type: :double)
  field(:vega, 9, proto3_optional: true, type: :double)
  field(:theta, 10, proto3_optional: true, type: :double)
  field(:und_price, 11, json_name: "undPrice", proto3_optional: true, type: :double)
end
