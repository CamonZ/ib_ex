defmodule IbEx.Client.Proto.Protobuf.CalculateImpliedVolatilityRequest.ImpliedVolatilityOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CalculateImpliedVolatilityRequest.ImpliedVolatilityOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.CalculateImpliedVolatilityRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CalculateImpliedVolatilityRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:option_price, 3, json_name: "optionPrice", proto3_optional: true, type: :double)
  field(:under_price, 4, json_name: "underPrice", proto3_optional: true, type: :double)

  field(:implied_volatility_options, 5,
    json_name: "impliedVolatilityOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.CalculateImpliedVolatilityRequest.ImpliedVolatilityOptionsEntry,
    map: true
  )
end
