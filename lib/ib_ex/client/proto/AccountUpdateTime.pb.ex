defmodule IbEx.Client.Proto.Protobuf.AccountUpdateTime do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AccountUpdateTime",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:time_stamp, 1, json_name: "timeStamp", proto3_optional: true, type: :string)
end
