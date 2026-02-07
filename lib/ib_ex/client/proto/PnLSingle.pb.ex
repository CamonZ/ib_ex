defmodule IbEx.Client.Proto.Protobuf.PnLSingle do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.PnLSingle",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:position, 2, proto3_optional: true, type: :string)
  field(:daily_pn_l, 3, json_name: "dailyPnL", proto3_optional: true, type: :double)
  field(:unrealized_pn_l, 4, json_name: "unrealizedPnL", proto3_optional: true, type: :double)
  field(:realized_pn_l, 5, json_name: "realizedPnL", proto3_optional: true, type: :double)
  field(:value, 6, proto3_optional: true, type: :double)
end
