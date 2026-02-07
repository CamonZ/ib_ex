defmodule IbEx.Client.Proto.Protobuf.HistoricalSession do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalSession",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:start_date_time, 1, json_name: "startDateTime", proto3_optional: true, type: :string)
  field(:end_date_time, 2, json_name: "endDateTime", proto3_optional: true, type: :string)
  field(:ref_date, 3, json_name: "refDate", proto3_optional: true, type: :string)
end
