defmodule IbEx.Client.Proto.Protobuf.HistogramData do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistogramData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:histogram_data_entries, 2,
    json_name: "histogramDataEntries",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.HistogramDataEntry
  )
end
