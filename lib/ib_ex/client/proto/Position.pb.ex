defmodule IbEx.Client.Proto.Protobuf.Position do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.Position",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:account, 1, proto3_optional: true, type: :string)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:position, 3, proto3_optional: true, type: :string)
  field(:avg_cost, 4, json_name: "avgCost", proto3_optional: true, type: :double)
end
