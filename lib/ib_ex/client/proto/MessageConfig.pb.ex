defmodule IbEx.Client.Proto.Protobuf.MessageConfig do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.MessageConfig",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:id, 1, proto3_optional: true, type: :int32)
  field(:title, 2, proto3_optional: true, type: :string)
  field(:message, 3, proto3_optional: true, type: :string)
  field(:default_action, 4, json_name: "defaultAction", proto3_optional: true, type: :string)
  field(:enabled, 5, proto3_optional: true, type: :bool)
end
