defmodule IbEx.Client.Proto.Protobuf.MarketRule do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MarketRule",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:market_rule_id, 1, json_name: "marketRuleId", proto3_optional: true, type: :int32)

  field(:price_increments, 2,
    json_name: "priceIncrements",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.PriceIncrement
  )
end
