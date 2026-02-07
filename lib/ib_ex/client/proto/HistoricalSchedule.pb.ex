defmodule IbEx.Client.Proto.Protobuf.HistoricalSchedule do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalSchedule",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:start_date_time, 2, json_name: "startDateTime", proto3_optional: true, type: :string)
  field(:end_date_time, 3, json_name: "endDateTime", proto3_optional: true, type: :string)
  field(:time_zone, 4, json_name: "timeZone", proto3_optional: true, type: :string)

  field(:historical_sessions, 5,
    json_name: "historicalSessions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.HistoricalSession
  )
end
