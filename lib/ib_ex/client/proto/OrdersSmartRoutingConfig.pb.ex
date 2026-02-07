defmodule IbEx.Client.Proto.Protobuf.OrdersSmartRoutingConfig do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrdersSmartRoutingConfig",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:seek_price_improvement, 1, json_name: "seekPriceImprovement", proto3_optional: true, type: :bool)
  field(:pre_open_reroute, 2, json_name: "preOpenReroute", proto3_optional: true, type: :bool)
  field(:do_not_route_to_dark_pools, 3, json_name: "doNotRouteToDarkPools", proto3_optional: true, type: :bool)
  field(:default_algorithm, 4, json_name: "defaultAlgorithm", proto3_optional: true, type: :string)
end
