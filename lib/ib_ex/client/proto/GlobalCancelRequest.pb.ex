defmodule IbEx.Client.Proto.Protobuf.GlobalCancelRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.GlobalCancelRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:order_cancel, 1, json_name: "orderCancel", proto3_optional: true, type: IbEx.Client.Proto.Protobuf.OrderCancel)
end
