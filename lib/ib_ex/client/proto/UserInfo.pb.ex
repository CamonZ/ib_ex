defmodule IbEx.Client.Proto.Protobuf.UserInfo do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.UserInfo",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:white_branding_id, 2, json_name: "whiteBrandingId", proto3_optional: true, type: :string)
end
