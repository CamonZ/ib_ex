defmodule IbEx.Client.Proto.Protobuf.NewsProviders do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NewsProviders",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:news_providers, 1, json_name: "newsProviders", repeated: true, type: IbEx.Client.Proto.Protobuf.NewsProvider)
end
