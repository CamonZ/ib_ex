defmodule IbEx.Client.Proto.Protobuf.IneligibilityReason do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.IneligibilityReason",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:id, 1, proto3_optional: true, type: :string)
  field(:description, 2, proto3_optional: true, type: :string)
end
