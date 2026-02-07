defmodule IbEx.Client.Proto.Protobuf.HistoricalDataBar do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalDataBar",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:date, 1, proto3_optional: true, type: :string)
  field(:open, 2, proto3_optional: true, type: :double)
  field(:high, 3, proto3_optional: true, type: :double)
  field(:low, 4, proto3_optional: true, type: :double)
  field(:close, 5, proto3_optional: true, type: :double)
  field(:volume, 6, proto3_optional: true, type: :string)
  field(:wap, 7, json_name: "WAP", proto3_optional: true, type: :string)
  field(:bar_count, 8, json_name: "barCount", proto3_optional: true, type: :int32)
end
