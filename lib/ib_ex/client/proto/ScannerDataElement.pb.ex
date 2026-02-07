defmodule IbEx.Client.Proto.Protobuf.ScannerDataElement do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ScannerDataElement",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:rank, 1, proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:market_name, 3, json_name: "marketName", proto3_optional: true, type: :string)
  field(:distance, 4, proto3_optional: true, type: :string)
  field(:benchmark, 5, proto3_optional: true, type: :string)
  field(:projection, 6, proto3_optional: true, type: :string)
  field(:combo_key, 7, json_name: "comboKey", proto3_optional: true, type: :string)
end
