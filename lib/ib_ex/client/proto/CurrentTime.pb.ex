defmodule IbEx.Client.Proto.Protobuf.CurrentTime do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CurrentTime",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:current_time, 1, json_name: "currentTime", proto3_optional: true, type: :int64)
end
