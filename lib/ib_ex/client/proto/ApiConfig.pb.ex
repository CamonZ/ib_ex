defmodule IbEx.Client.Proto.Protobuf.ApiConfig do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ApiConfig",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:precautions, 1,
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.ApiPrecautionsConfig
  )

  field(:settings, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.ApiSettingsConfig)
end
