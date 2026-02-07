defmodule IbEx.Client.Proto.Protobuf.ExerciseOptionsRequest do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ExerciseOptionsRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:order_id, 1, json_name: "orderId", proto3_optional: true, type: :int32)
  field(:contract, 2, proto3_optional: true, type: IbEx.Client.Proto.Protobuf.Contract)
  field(:exercise_action, 3, json_name: "exerciseAction", proto3_optional: true, type: :int32)
  field(:exercise_quantity, 4, json_name: "exerciseQuantity", proto3_optional: true, type: :int32)
  field(:account, 5, proto3_optional: true, type: :string)
  field(:override, 6, proto3_optional: true, type: :bool)
  field(:manual_order_time, 7, json_name: "manualOrderTime", proto3_optional: true, type: :string)
  field(:customer_account, 8, json_name: "customerAccount", proto3_optional: true, type: :string)
  field(:professional_customer, 9, json_name: "professionalCustomer", proto3_optional: true, type: :bool)
end
