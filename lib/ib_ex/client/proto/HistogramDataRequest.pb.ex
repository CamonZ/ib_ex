defmodule IbEx.Client.Proto.Protobuf.HistogramDataRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistogramDataRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:use_rth, 3, json_name: "useRTH", proto3_optional: true, type: :bool)
  field(:time_period, 4, json_name: "timePeriod", proto3_optional: true, type: :string)
end
