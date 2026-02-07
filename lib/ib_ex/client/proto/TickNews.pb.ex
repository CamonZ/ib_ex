defmodule IbEx.Client.Proto.Protobuf.TickNews do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickNews",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:timestamp, 2, proto3_optional: true, type: :int64)
  field(:provider_code, 3, json_name: "providerCode", proto3_optional: true, type: :string)
  field(:article_id, 4, json_name: "articleId", proto3_optional: true, type: :string)
  field(:headline, 5, proto3_optional: true, type: :string)
  field(:extra_data, 6, json_name: "extraData", proto3_optional: true, type: :string)
end
