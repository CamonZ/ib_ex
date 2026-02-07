defmodule IbEx.Client.Proto.Protobuf.OrderStatus do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrderStatus",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:order_id, 1, json_name: "orderId", proto3_optional: true, type: :int32)
  field(:status, 2, proto3_optional: true, type: :string)
  field(:filled, 3, proto3_optional: true, type: :string)
  field(:remaining, 4, proto3_optional: true, type: :string)
  field(:avg_fill_price, 5, json_name: "avgFillPrice", proto3_optional: true, type: :double)
  field(:perm_id, 6, json_name: "permId", proto3_optional: true, type: :int64)
  field(:parent_id, 7, json_name: "parentId", proto3_optional: true, type: :int32)
  field(:last_fill_price, 8, json_name: "lastFillPrice", proto3_optional: true, type: :double)
  field(:client_id, 9, json_name: "clientId", proto3_optional: true, type: :int32)
  field(:why_held, 10, json_name: "whyHeld", proto3_optional: true, type: :string)
  field(:mkt_cap_price, 11, json_name: "mktCapPrice", proto3_optional: true, type: :double)
end
