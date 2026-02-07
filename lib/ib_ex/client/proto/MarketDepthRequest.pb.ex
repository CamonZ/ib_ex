defmodule IbEx.Client.Proto.Protobuf.MarketDepthRequest.MarketDepthOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDepthRequest.MarketDepthOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.MarketDepthRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketDepthRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:num_rows, 3, json_name: "numRows", proto3_optional: true, type: :int32)
  field(:is_smart_depth, 4, json_name: "isSmartDepth", proto3_optional: true, type: :bool)

  field(:market_depth_options, 5,
    json_name: "marketDepthOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.MarketDepthRequest.MarketDepthOptionsEntry,
    map: true
  )
end
