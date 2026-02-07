defmodule IbEx.Client.Proto.Protobuf.TickAttribLast do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickAttribLast",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:past_limit, 1, json_name: "pastLimit", proto3_optional: true, type: :bool)
  field(:unreported, 2, proto3_optional: true, type: :bool)
end
