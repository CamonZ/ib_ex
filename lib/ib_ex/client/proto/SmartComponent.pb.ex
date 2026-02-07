defmodule IbEx.Client.Proto.Protobuf.SmartComponent do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.SmartComponent",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:bit_number, 1, json_name: "bitNumber", proto3_optional: true, type: :int32)
  field(:exchange, 2, proto3_optional: true, type: :string)
  field(:exchange_letter, 3, json_name: "exchangeLetter", proto3_optional: true, type: :string)
end
