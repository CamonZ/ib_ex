defmodule IbEx.Client.Proto.Protobuf.HistoricalTickBidAsk do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalTickBidAsk",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:time, 1, proto3_optional: true, type: :int64)

  field(:tick_attrib_bid_ask, 2,
    json_name: "tickAttribBidAsk",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.TickAttribBidAsk
  )

  field(:price_bid, 3, json_name: "priceBid", proto3_optional: true, type: :double)
  field(:price_ask, 4, json_name: "priceAsk", proto3_optional: true, type: :double)
  field(:size_bid, 5, json_name: "sizeBid", proto3_optional: true, type: :string)
  field(:size_ask, 6, json_name: "sizeAsk", proto3_optional: true, type: :string)
end
