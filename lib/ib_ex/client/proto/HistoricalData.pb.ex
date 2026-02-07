defmodule IbEx.Client.Proto.Protobuf.HistoricalData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:historical_data_bars, 2,
    json_name: "historicalDataBars",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.HistoricalDataBar
  )
end
