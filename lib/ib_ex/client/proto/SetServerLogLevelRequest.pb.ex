defmodule IbEx.Client.Proto.Protobuf.SetServerLogLevelRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SetServerLogLevelRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:log_level, 1, json_name: "logLevel", proto3_optional: true, type: :int32)
end
