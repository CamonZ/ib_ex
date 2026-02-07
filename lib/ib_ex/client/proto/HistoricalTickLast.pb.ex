defmodule IbEx.Client.Proto.Protobuf.HistoricalTickLast do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.HistoricalTickLast",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:time, 1, proto3_optional: true, type: :int64)

  field(:tick_attrib_last, 2,
    json_name: "tickAttribLast",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.TickAttribLast
  )

  field(:price, 3, proto3_optional: true, type: :double)
  field(:size, 4, proto3_optional: true, type: :string)
  field(:exchange, 5, proto3_optional: true, type: :string)
  field(:special_conditions, 6, json_name: "specialConditions", proto3_optional: true, type: :string)
end
