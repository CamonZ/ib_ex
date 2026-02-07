defmodule IbEx.Client.Proto.Protobuf.SecDefOptParameter do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SecDefOptParameter",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:exchange, 2, proto3_optional: true, type: :string)
  field(:underlying_con_id, 3, json_name: "underlyingConId", proto3_optional: true, type: :int32)
  field(:trading_class, 4, json_name: "tradingClass", proto3_optional: true, type: :string)
  field(:multiplier, 5, proto3_optional: true, type: :string)
  field(:expirations, 6, repeated: true, type: :string)
  field(:strikes, 7, repeated: true, type: :double)
end
