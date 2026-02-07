defmodule IbEx.Client.Proto.Protobuf.HeadTimestampRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HeadTimestampRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:use_rth, 3, json_name: "useRTH", proto3_optional: true, type: :bool)
  field(:what_to_show, 4, json_name: "whatToShow", proto3_optional: true, type: :string)
  field(:format_date, 5, json_name: "formatDate", proto3_optional: true, type: :int32)
end
