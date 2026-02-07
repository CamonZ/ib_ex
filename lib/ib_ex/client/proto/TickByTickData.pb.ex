defmodule IbEx.Client.Proto.Protobuf.TickByTickData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickByTickData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  oneof(:tick, 0)

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:tick_type, 2, json_name: "tickType", proto3_optional: true, type: :int32)

  field(:historical_tick_last, 3,
    json_name: "historicalTickLast",
    type: IbEx.Client.Proto.Protobuf.HistoricalTickLast,
    oneof: 0
  )

  field(:historical_tick_bid_ask, 4,
    json_name: "historicalTickBidAsk",
    type: IbEx.Client.Proto.Protobuf.HistoricalTickBidAsk,
    oneof: 0
  )

  field(:historical_tick_mid_point, 5,
    json_name: "historicalTickMidPoint",
    type: IbEx.Client.Proto.Protobuf.HistoricalTick,
    oneof: 0
  )
end
