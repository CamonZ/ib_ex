defmodule IbEx.Client.Proto.Protobuf.FAReplace do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.FAReplace",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:fa_data_type, 2, json_name: "faDataType", proto3_optional: true, type: :int32)
  field(:xml, 3, proto3_optional: true, type: :string)
end
