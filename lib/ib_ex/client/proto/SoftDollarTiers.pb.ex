defmodule IbEx.Client.Proto.Protobuf.SoftDollarTiers do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SoftDollarTiers",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:soft_dollar_tiers, 2,
    json_name: "softDollarTiers",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.SoftDollarTier
  )
end
