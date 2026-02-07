defmodule IbEx.Client.Proto.Protobuf.HistoricalTick do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalTick",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:time, 1, proto3_optional: true, type: :int64)
  field(:price, 2, proto3_optional: true, type: :double)
  field(:size, 3, proto3_optional: true, type: :string)
end
