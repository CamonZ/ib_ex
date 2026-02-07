defmodule IbEx.Client.Proto.Protobuf.ComboLeg do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ComboLeg",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:con_id, 1, json_name: "conId", proto3_optional: true, type: :int32)
  field(:ratio, 2, proto3_optional: true, type: :int32)
  field(:action, 3, proto3_optional: true, type: :string)
  field(:exchange, 4, proto3_optional: true, type: :string)
  field(:open_close, 5, json_name: "openClose", proto3_optional: true, type: :int32)
  field(:short_sales_slot, 6, json_name: "shortSalesSlot", proto3_optional: true, type: :int32)
  field(:designated_location, 7, json_name: "designatedLocation", proto3_optional: true, type: :string)
  field(:exempt_code, 8, json_name: "exemptCode", proto3_optional: true, type: :int32)
  field(:per_leg_price, 9, json_name: "perLegPrice", proto3_optional: true, type: :double)
end
