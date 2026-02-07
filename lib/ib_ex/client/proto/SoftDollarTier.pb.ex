defmodule IbEx.Client.Proto.Protobuf.SoftDollarTier do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SoftDollarTier",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:name, 1, proto3_optional: true, type: :string)
  field(:value, 2, proto3_optional: true, type: :string)
  field(:display_name, 3, json_name: "displayName", proto3_optional: true, type: :string)
end
