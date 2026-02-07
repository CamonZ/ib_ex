defmodule IbEx.Client.Proto.Protobuf.AccountValue do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.AccountValue",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, proto3_optional: true, type: :string)
  field(:value, 2, proto3_optional: true, type: :string)
  field(:currency, 3, proto3_optional: true, type: :string)
  field(:account_name, 4, json_name: "accountName", proto3_optional: true, type: :string)
end
