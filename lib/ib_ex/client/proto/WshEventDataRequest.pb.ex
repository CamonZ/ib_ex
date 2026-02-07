defmodule IbEx.Client.Proto.Protobuf.WshEventDataRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.WshEventDataRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:con_id, 2, json_name: "conId", proto3_optional: true, type: :int32)
  field(:filter, 3, proto3_optional: true, type: :string)
  field(:fill_watchlist, 4, json_name: "fillWatchlist", proto3_optional: true, type: :bool)
  field(:fill_portfolio, 5, json_name: "fillPortfolio", proto3_optional: true, type: :bool)
  field(:fill_competitors, 6, json_name: "fillCompetitors", proto3_optional: true, type: :bool)
  field(:start_date, 7, json_name: "startDate", proto3_optional: true, type: :string)
  field(:end_date, 8, json_name: "endDate", proto3_optional: true, type: :string)
  field(:total_limit, 9, json_name: "totalLimit", proto3_optional: true, type: :int32)
end
