defmodule IbEx.Client.Proto.Protobuf.TickByTickRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickByTickRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:tick_type, 3, json_name: "tickType", proto3_optional: true, type: :string)
  field(:number_of_ticks, 4, json_name: "numberOfTicks", proto3_optional: true, type: :int32)
  field(:ignore_size, 5, json_name: "ignoreSize", proto3_optional: true, type: :bool)
end
