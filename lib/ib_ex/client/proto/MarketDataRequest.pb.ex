defmodule IbEx.Client.Proto.Protobuf.MarketDataRequest.MarketDataOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDataRequest.MarketDataOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.MarketDataRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDataRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:generic_tick_list, 3, json_name: "genericTickList", proto3_optional: true, type: :string)
  field(:snapshot, 4, proto3_optional: true, type: :bool)
  field(:regulatory_snapshot, 5, json_name: "regulatorySnapshot", proto3_optional: true, type: :bool)

  field(:market_data_options, 6,
    json_name: "marketDataOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.MarketDataRequest.MarketDataOptionsEntry,
    map: true
  )
end
