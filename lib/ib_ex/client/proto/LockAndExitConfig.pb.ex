defmodule IbEx.Client.Proto.Protobuf.LockAndExitConfig do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.LockAndExitConfig",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:auto_logoff_time, 1, json_name: "autoLogoffTime", proto3_optional: true, type: :string)
  field(:auto_logoff_period, 2, json_name: "autoLogoffPeriod", proto3_optional: true, type: :string)
  field(:auto_logoff_type, 3, json_name: "autoLogoffType", proto3_optional: true, type: :string)
end
