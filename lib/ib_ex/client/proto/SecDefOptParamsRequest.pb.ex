defmodule IbEx.Client.Proto.Protobuf.SecDefOptParamsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SecDefOptParamsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:underlying_symbol, 2, json_name: "underlyingSymbol", proto3_optional: true, type: :string)
  field(:fut_fop_exchange, 3, json_name: "futFopExchange", proto3_optional: true, type: :string)
  field(:underlying_sec_type, 4, json_name: "underlyingSecType", proto3_optional: true, type: :string)
  field(:underlying_con_id, 5, json_name: "underlyingConId", proto3_optional: true, type: :int32)
end
