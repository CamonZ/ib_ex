defmodule IbEx.Client.Proto.Protobuf.PriceIncrement do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.PriceIncrement",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:low_edge, 1, json_name: "lowEdge", proto3_optional: true, type: :double)
  field(:increment, 2, proto3_optional: true, type: :double)
end
