defmodule IbEx.Client.Proto.Protobuf.Contract do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.Contract",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:con_id, 1, json_name: "conId", proto3_optional: true, type: :int32)
  field(:symbol, 2, proto3_optional: true, type: :string)
  field(:sec_type, 3, json_name: "secType", proto3_optional: true, type: :string)

  field(:last_trade_date_or_contract_month, 4,
    json_name: "lastTradeDateOrContractMonth",
    proto3_optional: true,
    type: :string
  )

  field(:strike, 5, proto3_optional: true, type: :double)
  field(:right, 6, proto3_optional: true, type: :string)
  field(:multiplier, 7, proto3_optional: true, type: :double)
  field(:exchange, 8, proto3_optional: true, type: :string)
  field(:primary_exch, 9, json_name: "primaryExch", proto3_optional: true, type: :string)
  field(:currency, 10, proto3_optional: true, type: :string)
  field(:local_symbol, 11, json_name: "localSymbol", proto3_optional: true, type: :string)
  field(:trading_class, 12, json_name: "tradingClass", proto3_optional: true, type: :string)
  field(:sec_id_type, 13, json_name: "secIdType", proto3_optional: true, type: :string)
  field(:sec_id, 14, json_name: "secId", proto3_optional: true, type: :string)
  field(:description, 15, proto3_optional: true, type: :string)
  field(:issuer_id, 16, json_name: "issuerId", proto3_optional: true, type: :string)

  field(:delta_neutral_contract, 17,
    json_name: "deltaNeutralContract",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.DeltaNeutralContract
  )

  field(:include_expired, 18, json_name: "includeExpired", proto3_optional: true, type: :bool)
  field(:combo_legs_descrip, 19, json_name: "comboLegsDescrip", proto3_optional: true, type: :string)
  field(:combo_legs, 20, json_name: "comboLegs", repeated: true, type: IbEx.Client.Proto.Protobuf.ComboLeg)
  field(:last_trade_date, 21, json_name: "lastTradeDate", proto3_optional: true, type: :string)
end
