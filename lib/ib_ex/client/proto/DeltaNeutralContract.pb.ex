defmodule IbEx.Client.Proto.Protobuf.DeltaNeutralContract do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.DeltaNeutralContract",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:con_id, 1, json_name: "conId", proto3_optional: true, type: :int32)
  field(:delta, 2, proto3_optional: true, type: :double)
  field(:price, 3, proto3_optional: true, type: :double)
end
