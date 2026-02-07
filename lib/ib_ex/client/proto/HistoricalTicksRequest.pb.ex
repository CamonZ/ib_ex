defmodule IbEx.Client.Proto.Protobuf.HistoricalTicksRequest.MiscOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalTicksRequest.MiscOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.HistoricalTicksRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalTicksRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:start_date_time, 3, json_name: "startDateTime", proto3_optional: true, type: :string)
  field(:end_date_time, 4, json_name: "endDateTime", proto3_optional: true, type: :string)
  field(:number_of_ticks, 5, json_name: "numberOfTicks", proto3_optional: true, type: :int32)
  field(:what_to_show, 6, json_name: "whatToShow", proto3_optional: true, type: :string)
  field(:use_rth, 7, json_name: "useRTH", proto3_optional: true, type: :bool)
  field(:ignore_size, 8, json_name: "ignoreSize", proto3_optional: true, type: :bool)

  field(:misc_options, 9,
    json_name: "miscOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.HistoricalTicksRequest.MiscOptionsEntry,
    map: true
  )
end
