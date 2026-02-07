defmodule IbEx.Client.Proto.Protobuf.NewsProvider do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NewsProvider",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:provider_code, 1, json_name: "providerCode", proto3_optional: true, type: :string)
  field(:provider_name, 2, json_name: "providerName", proto3_optional: true, type: :string)
end
