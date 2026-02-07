defmodule IbEx.Client.Proto.Protobuf.CurrentTimeInMillis do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.CurrentTimeInMillis",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:current_time_in_millis, 1, json_name: "currentTimeInMillis", proto3_optional: true, type: :int64)
end
