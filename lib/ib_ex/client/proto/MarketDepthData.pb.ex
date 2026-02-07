defmodule IbEx.Client.Proto.Protobuf.MarketDepthData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDepthData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:position, 1, proto3_optional: true, type: :int32)
  field(:operation, 2, proto3_optional: true, type: :int32)
  field(:side, 3, proto3_optional: true, type: :int32)
  field(:price, 4, proto3_optional: true, type: :double)
  field(:size, 5, proto3_optional: true, type: :string)
  field(:market_maker, 6, json_name: "marketMaker", proto3_optional: true, type: :string)
  field(:is_smart_depth, 7, json_name: "isSmartDepth", proto3_optional: true, type: :bool)
end
