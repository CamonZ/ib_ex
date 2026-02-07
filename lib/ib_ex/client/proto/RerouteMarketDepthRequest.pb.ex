defmodule IbEx.Client.Proto.Protobuf.RerouteMarketDepthRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.RerouteMarketDepthRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:con_id, 2, json_name: "conId", proto3_optional: true, type: :int32)
  field(:exchange, 3, proto3_optional: true, type: :string)
end
