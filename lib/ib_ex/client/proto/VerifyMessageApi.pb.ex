defmodule IbEx.Client.Proto.Protobuf.VerifyMessageApi do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.VerifyMessageApi",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:api_data, 1, json_name: "apiData", proto3_optional: true, type: :string)
end
