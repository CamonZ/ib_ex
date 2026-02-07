defmodule IbEx.Client.Proto.Protobuf.OrderState do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.OrderState",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:status, 1, proto3_optional: true, type: :string)
  field(:init_margin_before, 2, json_name: "initMarginBefore", proto3_optional: true, type: :double)
  field(:maint_margin_before, 3, json_name: "maintMarginBefore", proto3_optional: true, type: :double)
  field(:equity_with_loan_before, 4, json_name: "equityWithLoanBefore", proto3_optional: true, type: :double)
  field(:init_margin_change, 5, json_name: "initMarginChange", proto3_optional: true, type: :double)
  field(:maint_margin_change, 6, json_name: "maintMarginChange", proto3_optional: true, type: :double)
  field(:equity_with_loan_change, 7, json_name: "equityWithLoanChange", proto3_optional: true, type: :double)
  field(:init_margin_after, 8, json_name: "initMarginAfter", proto3_optional: true, type: :double)
  field(:maint_margin_after, 9, json_name: "maintMarginAfter", proto3_optional: true, type: :double)
  field(:equity_with_loan_after, 10, json_name: "equityWithLoanAfter", proto3_optional: true, type: :double)
  field(:commission_and_fees, 11, json_name: "commissionAndFees", proto3_optional: true, type: :double)
  field(:min_commission_and_fees, 12, json_name: "minCommissionAndFees", proto3_optional: true, type: :double)
  field(:max_commission_and_fees, 13, json_name: "maxCommissionAndFees", proto3_optional: true, type: :double)
  field(:commission_and_fees_currency, 14, json_name: "commissionAndFeesCurrency", proto3_optional: true, type: :string)
  field(:margin_currency, 15, json_name: "marginCurrency", proto3_optional: true, type: :string)

  field(:init_margin_before_outside_rth, 16,
    json_name: "initMarginBeforeOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:maint_margin_before_outside_rth, 17,
    json_name: "maintMarginBeforeOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:equity_with_loan_before_outside_rth, 18,
    json_name: "equityWithLoanBeforeOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:init_margin_change_outside_rth, 19,
    json_name: "initMarginChangeOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:maint_margin_change_outside_rth, 20,
    json_name: "maintMarginChangeOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:equity_with_loan_change_outside_rth, 21,
    json_name: "equityWithLoanChangeOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:init_margin_after_outside_rth, 22,
    json_name: "initMarginAfterOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:maint_margin_after_outside_rth, 23,
    json_name: "maintMarginAfterOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:equity_with_loan_after_outside_rth, 24,
    json_name: "equityWithLoanAfterOutsideRTH",
    proto3_optional: true,
    type: :double
  )

  field(:suggested_size, 25, json_name: "suggestedSize", proto3_optional: true, type: :string)
  field(:reject_reason, 26, json_name: "rejectReason", proto3_optional: true, type: :string)

  field(:order_allocations, 27,
    json_name: "orderAllocations",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.OrderAllocation
  )

  field(:warning_text, 28, json_name: "warningText", proto3_optional: true, type: :string)
  field(:completed_time, 29, json_name: "completedTime", proto3_optional: true, type: :string)
  field(:completed_status, 30, json_name: "completedStatus", proto3_optional: true, type: :string)
end
