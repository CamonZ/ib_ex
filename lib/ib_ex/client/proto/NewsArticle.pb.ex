defmodule IbEx.Client.Proto.Protobuf.NewsArticle do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NewsArticle",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:article_type, 2, json_name: "articleType", proto3_optional: true, type: :int32)
  field(:article_text, 3, json_name: "articleText", proto3_optional: true, type: :string)
end
