defmodule IbEx.Client.Proto.Protobuf.NewsBulletin do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.NewsBulletin",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:news_msg_id, 1, json_name: "newsMsgId", proto3_optional: true, type: :int32)
  field(:news_msg_type, 2, json_name: "newsMsgType", proto3_optional: true, type: :int32)
  field(:news_message, 3, json_name: "newsMessage", proto3_optional: true, type: :string)
  field(:originating_exch, 4, json_name: "originatingExch", proto3_optional: true, type: :string)
end
