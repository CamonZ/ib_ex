defmodule IbEx.Client.Proto.Protobuf.ReceiveFA do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ReceiveFA",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:fa_data_type, 1, json_name: "faDataType", proto3_optional: true, type: :int32)
  field(:xml, 2, proto3_optional: true, type: :string)
end
