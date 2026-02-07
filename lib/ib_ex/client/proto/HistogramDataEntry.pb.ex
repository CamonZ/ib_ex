defmodule IbEx.Client.Proto.Protobuf.HistogramDataEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistogramDataEntry",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:price, 1, proto3_optional: true, type: :double)
  field(:size, 2, proto3_optional: true, type: :string)
end
