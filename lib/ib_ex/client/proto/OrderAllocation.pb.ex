defmodule IbEx.Client.Proto.Protobuf.OrderAllocation do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrderAllocation",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:account, 1, proto3_optional: true, type: :string)
  field(:position, 2, proto3_optional: true, type: :string)
  field(:position_desired, 3, json_name: "positionDesired", proto3_optional: true, type: :string)
  field(:position_after, 4, json_name: "positionAfter", proto3_optional: true, type: :string)
  field(:desired_alloc_qty, 5, json_name: "desiredAllocQty", proto3_optional: true, type: :string)
  field(:allowed_alloc_qty, 6, json_name: "allowedAllocQty", proto3_optional: true, type: :string)
  field(:is_monetary, 7, json_name: "isMonetary", proto3_optional: true, type: :bool)
end
