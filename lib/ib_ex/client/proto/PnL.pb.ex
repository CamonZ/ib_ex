defmodule IbEx.Client.Proto.Protobuf.PnL do
  @moduledoc false

  use Protobuf, full_name: "protobuf.PnL", protoc_gen_elixir_version: "0.16.0", syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:daily_pn_l, 2, json_name: "dailyPnL", proto3_optional: true, type: :double)
  field(:unrealized_pn_l, 3, json_name: "unrealizedPnL", proto3_optional: true, type: :double)
  field(:realized_pn_l, 4, json_name: "realizedPnL", proto3_optional: true, type: :double)
end
