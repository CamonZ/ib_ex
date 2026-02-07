defmodule IbEx.Client.Proto.Protobuf.ScannerParameters do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ScannerParameters",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:xml, 1, proto3_optional: true, type: :string)
end
