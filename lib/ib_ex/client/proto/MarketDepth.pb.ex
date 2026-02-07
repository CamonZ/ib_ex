defmodule IbEx.Client.Proto.Protobuf.MarketDepth do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDepth",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:market_depth_data, 2,
    json_name: "marketDepthData",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.MarketDepthData
  )
end
