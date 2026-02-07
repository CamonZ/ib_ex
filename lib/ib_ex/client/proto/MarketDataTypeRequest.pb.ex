defmodule IbEx.Client.Proto.Protobuf.MarketDataTypeRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDataTypeRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:market_data_type, 1, json_name: "marketDataType", proto3_optional: true, type: :int32)
end
