defmodule IbEx.Client.Proto.Protobuf.FundamentalsDataRequest.FundamentalsDataOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.FundamentalsDataRequest.FundamentalsDataOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.FundamentalsDataRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.FundamentalsDataRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:report_type, 3, json_name: "reportType", proto3_optional: true, type: :string)

  field(:fundamentals_data_options, 4,
    json_name: "fundamentalsDataOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.FundamentalsDataRequest.FundamentalsDataOptionsEntry,
    map: true
  )
end
