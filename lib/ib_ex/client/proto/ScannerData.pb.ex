defmodule IbEx.Client.Proto.Protobuf.ScannerData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ScannerData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:scanner_data_element, 2,
    json_name: "scannerDataElement",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.ScannerDataElement
  )
end
