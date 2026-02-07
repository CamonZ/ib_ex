defmodule IbEx.Client.Proto.Protobuf.MarketDataType do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDataType",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:market_data_type, 2, json_name: "marketDataType", proto3_optional: true, type: :int32)
end
