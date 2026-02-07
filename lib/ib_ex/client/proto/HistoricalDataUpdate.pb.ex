defmodule IbEx.Client.Proto.Protobuf.HistoricalDataUpdate do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalDataUpdate",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:historical_data_bar, 2,
    json_name: "historicalDataBar",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.HistoricalDataBar
  )
end
