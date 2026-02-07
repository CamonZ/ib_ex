defmodule IbEx.Client.Proto.Protobuf.HistoricalTicks do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalTicks",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:historical_ticks, 2,
    json_name: "historicalTicks",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.HistoricalTick
  )

  field(:is_done, 3, json_name: "isDone", proto3_optional: true, type: :bool)
end
