defmodule IbEx.Client.Proto.Protobuf.NewsArticleRequest.NewsArticleOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NewsArticleRequest.NewsArticleOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.NewsArticleRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NewsArticleRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:req_id, 1, json_name: "reqId", proto3_optional: true, type: :int32)
  field(:provider_code, 2, json_name: "providerCode", proto3_optional: true, type: :string)
  field(:article_id, 3, json_name: "articleId", proto3_optional: true, type: :string)

  field(:news_article_options, 4,
    json_name: "newsArticleOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.NewsArticleRequest.NewsArticleOptionsEntry,
    map: true
  )
end
