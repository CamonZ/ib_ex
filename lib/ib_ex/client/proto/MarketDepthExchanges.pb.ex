defmodule IbEx.Client.Proto.Protobuf.MarketDepthExchanges do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDepthExchanges",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:depth_market_data_descriptions, 1,
    json_name: "depthMarketDataDescriptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.DepthMarketDataDescription
  )
end
