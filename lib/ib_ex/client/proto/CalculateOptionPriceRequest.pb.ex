defmodule IbEx.Client.Proto.Protobuf.CalculateOptionPriceRequest.OptionPriceOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CalculateOptionPriceRequest.OptionPriceOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.CalculateOptionPriceRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CalculateOptionPriceRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:volatility, 3, proto3_optional: true, type: :double)
  field(:under_price, 4, json_name: "underPrice", proto3_optional: true, type: :double)

  field(:option_price_options, 5,
    json_name: "optionPriceOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.CalculateOptionPriceRequest.OptionPriceOptionsEntry,
    map: true
  )
end
