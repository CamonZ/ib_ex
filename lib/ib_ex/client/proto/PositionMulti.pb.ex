defmodule IbEx.Client.Proto.Protobuf.PositionMulti do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.PositionMulti",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:account, 2, proto3_optional: true, type: :string)
  field(:contract, 3, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:position, 4, proto3_optional: true, type: :string)
  field(:avg_cost, 5, json_name: "avgCost", proto3_optional: true, type: :double)
  field(:model_code, 6, json_name: "modelCode", proto3_optional: true, type: :string)
end
