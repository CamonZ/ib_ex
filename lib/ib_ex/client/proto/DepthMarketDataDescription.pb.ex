defmodule IbEx.Client.Proto.Protobuf.DepthMarketDataDescription do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.DepthMarketDataDescription",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:exchange, 1, proto3_optional: true, type: :string)
  field(:sec_type, 2, json_name: "secType", proto3_optional: true, type: :string)
  field(:listing_exch, 3, json_name: "listingExch", proto3_optional: true, type: :string)
  field(:service_data_type, 4, json_name: "serviceDataType", proto3_optional: true, type: :string)
  field(:agg_group, 5, json_name: "aggGroup", proto3_optional: true, type: :int32)
end
