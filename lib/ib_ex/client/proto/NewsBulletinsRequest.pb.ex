defmodule IbEx.Client.Proto.Protobuf.NewsBulletinsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NewsBulletinsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:all_messages, 1, json_name: "allMessages", proto3_optional: true, type: :bool)
end
