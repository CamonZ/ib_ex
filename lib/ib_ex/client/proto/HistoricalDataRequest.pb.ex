defmodule IbEx.Client.Proto.Protobuf.HistoricalDataRequest.ChartOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalDataRequest.ChartOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.HistoricalDataRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalDataRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:end_date_time, 3, json_name: "endDateTime", proto3_optional: true, type: :string)
  field(:bar_size_setting, 4, json_name: "barSizeSetting", proto3_optional: true, type: :string)
  field(:duration, 5, proto3_optional: true, type: :string)
  field(:use_rth, 6, json_name: "useRTH", proto3_optional: true, type: :bool)
  field(:what_to_show, 7, json_name: "whatToShow", proto3_optional: true, type: :string)
  field(:format_date, 8, json_name: "formatDate", proto3_optional: true, type: :int32)
  field(:keep_up_to_date, 9, json_name: "keepUpToDate", proto3_optional: true, type: :bool)

  field(:chart_options, 10,
    json_name: "chartOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.HistoricalDataRequest.ChartOptionsEntry,
    map: true
  )
end
