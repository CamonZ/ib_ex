defmodule IbEx.Client.Proto.Protobuf.HistoricalNewsRequest.HistoricalNewsOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalNewsRequest.HistoricalNewsOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.HistoricalNewsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalNewsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:con_id, 2, json_name: "conId", proto3_optional: true, type: :int32)
  field(:provider_codes, 3, json_name: "providerCodes", proto3_optional: true, type: :string)
  field(:start_date_time, 4, json_name: "startDateTime", proto3_optional: true, type: :string)
  field(:end_date_time, 5, json_name: "endDateTime", proto3_optional: true, type: :string)
  field(:total_results, 6, json_name: "totalResults", proto3_optional: true, type: :int32)

  field(:historical_news_options, 7,
    json_name: "historicalNewsOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.HistoricalNewsRequest.HistoricalNewsOptionsEntry,
    map: true
  )
end
