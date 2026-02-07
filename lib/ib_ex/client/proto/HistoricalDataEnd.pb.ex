defmodule IbEx.Client.Proto.Protobuf.HistoricalDataEnd do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalDataEnd",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:start_date_str, 2, json_name: "startDateStr", proto3_optional: true, type: :string)
  field(:end_date_str, 3, json_name: "endDateStr", proto3_optional: true, type: :string)
end
