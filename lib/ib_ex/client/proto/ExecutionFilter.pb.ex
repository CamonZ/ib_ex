defmodule IbEx.Client.Proto.Protobuf.ExecutionFilter do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ExecutionFilter",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:client_id, 1, json_name: "clientId", proto3_optional: true, type: :int32)
  field(:acct_code, 2, json_name: "acctCode", proto3_optional: true, type: :string)
  field(:time, 3, proto3_optional: true, type: :string)
  field(:symbol, 4, proto3_optional: true, type: :string)
  field(:sec_type, 5, json_name: "secType", proto3_optional: true, type: :string)
  field(:exchange, 6, proto3_optional: true, type: :string)
  field(:side, 7, proto3_optional: true, type: :string)
  field(:last_n_days, 8, json_name: "lastNDays", proto3_optional: true, type: :int32)
  field(:specific_dates, 9, json_name: "specificDates", repeated: true, type: :int32)
end
