defmodule IbEx.Client.Proto.Protobuf.ConfigResponse do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ConfigResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)

  field(:lock_and_exit, 2,
    json_name: "lockAndExit",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.LockAndExitConfig
  )

  field(:messages, 3, repeated: true, type: IbEx.Client.Proto.Protobuf.MessageConfig)
  field(:api, 4, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.ApiConfig)
  field(:orders, 5, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.OrdersConfig)
end
