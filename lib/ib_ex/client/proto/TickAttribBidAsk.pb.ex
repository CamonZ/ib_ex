defmodule IbEx.Client.Proto.Protobuf.TickAttribBidAsk do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.TickAttribBidAsk",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:bid_past_low, 1, json_name: "bidPastLow", proto3_optional: true, type: :bool)
  field(:ask_past_high, 2, json_name: "askPastHigh", proto3_optional: true, type: :bool)
end
