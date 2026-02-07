defmodule IbEx.Client.Proto.Protobuf.RealTimeBarsRequest.RealTimeBarsOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.RealTimeBarsRequest.RealTimeBarsOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.RealTimeBarsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.RealTimeBarsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:bar_size, 3, json_name: "barSize", proto3_optional: true, type: :int32)
  field(:what_to_show, 4, json_name: "whatToShow", proto3_optional: true, type: :string)
  field(:use_rth, 5, json_name: "useRTH", proto3_optional: true, type: :bool)

  field(:real_time_bars_options, 6,
    json_name: "realTimeBarsOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.RealTimeBarsRequest.RealTimeBarsOptionsEntry,
    map: true
  )
end
