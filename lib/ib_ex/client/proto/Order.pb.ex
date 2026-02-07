defmodule IbEx.Client.Proto.Protobuf.Order.AlgoParamsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.Order.AlgoParamsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.Order.SmartComboRoutingParamsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.Order.SmartComboRoutingParamsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.Order.OrderMiscOptionsEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.Order.OrderMiscOptionsEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.Order do
  @moduledoc false

  use Protobuf, full_name: "protobuf.Order", protoc_gen_elixir_version: "0.16.0", syntax: :proto3

  field(:client_id, 1, json_name: "clientId", proto3_optional: true, type: :int32)
  field(:order_id, 2, json_name: "orderId", proto3_optional: true, type: :int32)
  field(:perm_id, 3, json_name: "permId", proto3_optional: true, type: :int64)
  field(:parent_id, 4, json_name: "parentId", proto3_optional: true, type: :int32)
  field(:action, 5, proto3_optional: true, type: :string)
  field(:total_quantity, 6, json_name: "totalQuantity", proto3_optional: true, type: :string)
  field(:display_size, 7, json_name: "displaySize", proto3_optional: true, type: :int32)
  field(:order_type, 8, json_name: "orderType", proto3_optional: true, type: :string)
  field(:lmt_price, 9, json_name: "lmtPrice", proto3_optional: true, type: :double)
  field(:aux_price, 10, json_name: "auxPrice", proto3_optional: true, type: :double)
  field(:tif, 11, proto3_optional: true, type: :string)
  field(:account, 12, proto3_optional: true, type: :string)
  field(:settling_firm, 13, json_name: "settlingFirm", proto3_optional: true, type: :string)
  field(:clearing_account, 14, json_name: "clearingAccount", proto3_optional: true, type: :string)
  field(:clearing_intent, 15, json_name: "clearingIntent", proto3_optional: true, type: :string)
  field(:all_or_none, 16, json_name: "allOrNone", proto3_optional: true, type: :bool)
  field(:block_order, 17, json_name: "blockOrder", proto3_optional: true, type: :bool)
  field(:hidden, 18, proto3_optional: true, type: :bool)
  field(:outside_rth, 19, json_name: "outsideRth", proto3_optional: true, type: :bool)
  field(:sweep_to_fill, 20, json_name: "sweepToFill", proto3_optional: true, type: :bool)
  field(:percent_offset, 21, json_name: "percentOffset", proto3_optional: true, type: :double)
  field(:trailing_percent, 22, json_name: "trailingPercent", proto3_optional: true, type: :double)
  field(:trail_stop_price, 23, json_name: "trailStopPrice", proto3_optional: true, type: :double)
  field(:min_qty, 24, json_name: "minQty", proto3_optional: true, type: :int32)
  field(:good_after_time, 25, json_name: "goodAfterTime", proto3_optional: true, type: :string)
  field(:good_till_date, 26, json_name: "goodTillDate", proto3_optional: true, type: :string)
  field(:oca_group, 27, json_name: "ocaGroup", proto3_optional: true, type: :string)
  field(:order_ref, 28, json_name: "orderRef", proto3_optional: true, type: :string)
  field(:rule80_a, 29, json_name: "rule80A", proto3_optional: true, type: :string)
  field(:oca_type, 30, json_name: "ocaType", proto3_optional: true, type: :int32)
  field(:trigger_method, 31, json_name: "triggerMethod", proto3_optional: true, type: :int32)
  field(:active_start_time, 32, json_name: "activeStartTime", proto3_optional: true, type: :string)
  field(:active_stop_time, 33, json_name: "activeStopTime", proto3_optional: true, type: :string)
  field(:fa_group, 34, json_name: "faGroup", proto3_optional: true, type: :string)
  field(:fa_method, 35, json_name: "faMethod", proto3_optional: true, type: :string)
  field(:fa_percentage, 36, json_name: "faPercentage", proto3_optional: true, type: :string)
  field(:volatility, 37, proto3_optional: true, type: :double)
  field(:volatility_type, 38, json_name: "volatilityType", proto3_optional: true, type: :int32)
  field(:continuous_update, 39, json_name: "continuousUpdate", proto3_optional: true, type: :bool)
  field(:reference_price_type, 40, json_name: "referencePriceType", proto3_optional: true, type: :int32)
  field(:delta_neutral_order_type, 41, json_name: "deltaNeutralOrderType", proto3_optional: true, type: :string)
  field(:delta_neutral_aux_price, 42, json_name: "deltaNeutralAuxPrice", proto3_optional: true, type: :double)
  field(:delta_neutral_con_id, 43, json_name: "deltaNeutralConId", proto3_optional: true, type: :int32)
  field(:delta_neutral_open_close, 44, json_name: "deltaNeutralOpenClose", proto3_optional: true, type: :string)
  field(:delta_neutral_short_sale, 45, json_name: "deltaNeutralShortSale", proto3_optional: true, type: :bool)
  field(:delta_neutral_short_sale_slot, 46, json_name: "deltaNeutralShortSaleSlot", proto3_optional: true, type: :int32)

  field(:delta_neutral_designated_location, 47,
    json_name: "deltaNeutralDesignatedLocation",
    proto3_optional: true,
    type: :string
  )

  field(:scale_init_level_size, 48, json_name: "scaleInitLevelSize", proto3_optional: true, type: :int32)
  field(:scale_subs_level_size, 49, json_name: "scaleSubsLevelSize", proto3_optional: true, type: :int32)
  field(:scale_price_increment, 50, json_name: "scalePriceIncrement", proto3_optional: true, type: :double)
  field(:scale_price_adjust_value, 51, json_name: "scalePriceAdjustValue", proto3_optional: true, type: :double)
  field(:scale_price_adjust_interval, 52, json_name: "scalePriceAdjustInterval", proto3_optional: true, type: :int32)
  field(:scale_profit_offset, 53, json_name: "scaleProfitOffset", proto3_optional: true, type: :double)
  field(:scale_auto_reset, 54, json_name: "scaleAutoReset", proto3_optional: true, type: :bool)
  field(:scale_init_position, 55, json_name: "scaleInitPosition", proto3_optional: true, type: :int32)
  field(:scale_init_fill_qty, 56, json_name: "scaleInitFillQty", proto3_optional: true, type: :int32)
  field(:scale_random_percent, 57, json_name: "scaleRandomPercent", proto3_optional: true, type: :bool)
  field(:scale_table, 58, json_name: "scaleTable", proto3_optional: true, type: :string)
  field(:hedge_type, 59, json_name: "hedgeType", proto3_optional: true, type: :string)
  field(:hedge_param, 60, json_name: "hedgeParam", proto3_optional: true, type: :string)
  field(:algo_strategy, 61, json_name: "algoStrategy", proto3_optional: true, type: :string)

  field(:algo_params, 62,
    json_name: "algoParams",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.Order.AlgoParamsEntry,
    map: true
  )

  field(:algo_id, 63, json_name: "algoId", proto3_optional: true, type: :string)

  field(:smart_combo_routing_params, 64,
    json_name: "smartComboRoutingParams",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.Order.SmartComboRoutingParamsEntry,
    map: true
  )

  field(:what_if, 65, json_name: "whatIf", proto3_optional: true, type: :bool)
  field(:transmit, 66, proto3_optional: true, type: :bool)

  field(:override_percentage_constraints, 67,
    json_name: "overridePercentageConstraints",
    proto3_optional: true,
    type: :bool
  )

  field(:open_close, 68, json_name: "openClose", proto3_optional: true, type: :string)
  field(:origin, 69, proto3_optional: true, type: :int32)
  field(:short_sale_slot, 70, json_name: "shortSaleSlot", proto3_optional: true, type: :int32)
  field(:designated_location, 71, json_name: "designatedLocation", proto3_optional: true, type: :string)
  field(:exempt_code, 72, json_name: "exemptCode", proto3_optional: true, type: :int32)
  field(:delta_neutral_settling_firm, 73, json_name: "deltaNeutralSettlingFirm", proto3_optional: true, type: :string)

  field(:delta_neutral_clearing_account, 74,
    json_name: "deltaNeutralClearingAccount",
    proto3_optional: true,
    type: :string
  )

  field(:delta_neutral_clearing_intent, 75,
    json_name: "deltaNeutralClearingIntent",
    proto3_optional: true,
    type: :string
  )

  field(:discretionary_amt, 76, json_name: "discretionaryAmt", proto3_optional: true, type: :double)
  field(:opt_out_smart_routing, 77, json_name: "optOutSmartRouting", proto3_optional: true, type: :bool)
  field(:starting_price, 78, json_name: "startingPrice", proto3_optional: true, type: :double)
  field(:stock_ref_price, 79, json_name: "stockRefPrice", proto3_optional: true, type: :double)
  field(:delta, 80, proto3_optional: true, type: :double)
  field(:stock_range_lower, 81, json_name: "stockRangeLower", proto3_optional: true, type: :double)
  field(:stock_range_upper, 82, json_name: "stockRangeUpper", proto3_optional: true, type: :double)
  field(:not_held, 83, json_name: "notHeld", proto3_optional: true, type: :bool)

  field(:order_misc_options, 84,
    json_name: "orderMiscOptions",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.Order.OrderMiscOptionsEntry,
    map: true
  )

  field(:solicited, 85, proto3_optional: true, type: :bool)
  field(:randomize_size, 86, json_name: "randomizeSize", proto3_optional: true, type: :bool)
  field(:randomize_price, 87, json_name: "randomizePrice", proto3_optional: true, type: :bool)
  field(:reference_contract_id, 88, json_name: "referenceContractId", proto3_optional: true, type: :int32)
  field(:pegged_change_amount, 89, json_name: "peggedChangeAmount", proto3_optional: true, type: :double)

  field(:is_pegged_change_amount_decrease, 90,
    json_name: "isPeggedChangeAmountDecrease",
    proto3_optional: true,
    type: :bool
  )

  field(:reference_change_amount, 91, json_name: "referenceChangeAmount", proto3_optional: true, type: :double)
  field(:reference_exchange_id, 92, json_name: "referenceExchangeId", proto3_optional: true, type: :string)
  field(:adjusted_order_type, 93, json_name: "adjustedOrderType", proto3_optional: true, type: :string)
  field(:trigger_price, 94, json_name: "triggerPrice", proto3_optional: true, type: :double)
  field(:adjusted_stop_price, 95, json_name: "adjustedStopPrice", proto3_optional: true, type: :double)
  field(:adjusted_stop_limit_price, 96, json_name: "adjustedStopLimitPrice", proto3_optional: true, type: :double)
  field(:adjusted_trailing_amount, 97, json_name: "adjustedTrailingAmount", proto3_optional: true, type: :double)
  field(:adjustable_trailing_unit, 98, json_name: "adjustableTrailingUnit", proto3_optional: true, type: :int32)
  field(:lmt_price_offset, 99, json_name: "lmtPriceOffset", proto3_optional: true, type: :double)
  field(:conditions, 100, repeated: true, type: IbEx.Client.Proto.Protobuf.OrderCondition)
  field(:conditions_cancel_order, 101, json_name: "conditionsCancelOrder", proto3_optional: true, type: :bool)
  field(:conditions_ignore_rth, 102, json_name: "conditionsIgnoreRth", proto3_optional: true, type: :bool)
  field(:model_code, 103, json_name: "modelCode", proto3_optional: true, type: :string)
  field(:ext_operator, 104, json_name: "extOperator", proto3_optional: true, type: :string)

  field(:soft_dollar_tier, 105,
    json_name: "softDollarTier",
    proto3_optional: true,
    type: IbEx.Client.Proto.Protobuf.SoftDollarTier
  )

  field(:cash_qty, 106, json_name: "cashQty", proto3_optional: true, type: :double)
  field(:mifid2_decision_maker, 107, json_name: "mifid2DecisionMaker", proto3_optional: true, type: :string)
  field(:mifid2_decision_algo, 108, json_name: "mifid2DecisionAlgo", proto3_optional: true, type: :string)
  field(:mifid2_execution_trader, 109, json_name: "mifid2ExecutionTrader", proto3_optional: true, type: :string)
  field(:mifid2_execution_algo, 110, json_name: "mifid2ExecutionAlgo", proto3_optional: true, type: :string)
  field(:dont_use_auto_price_for_hedge, 111, json_name: "dontUseAutoPriceForHedge", proto3_optional: true, type: :bool)
  field(:is_oms_container, 112, json_name: "isOmsContainer", proto3_optional: true, type: :bool)

  field(:discretionary_up_to_limit_price, 113,
    json_name: "discretionaryUpToLimitPrice",
    proto3_optional: true,
    type: :bool
  )

  field(:auto_cancel_date, 114, json_name: "autoCancelDate", proto3_optional: true, type: :string)
  field(:filled_quantity, 115, json_name: "filledQuantity", proto3_optional: true, type: :string)
  field(:ref_futures_con_id, 116, json_name: "refFuturesConId", proto3_optional: true, type: :int32)
  field(:auto_cancel_parent, 117, json_name: "autoCancelParent", proto3_optional: true, type: :bool)
  field(:shareholder, 118, proto3_optional: true, type: :string)
  field(:imbalance_only, 119, json_name: "imbalanceOnly", proto3_optional: true, type: :bool)
  field(:route_marketable_to_bbo, 120, json_name: "routeMarketableToBbo", proto3_optional: true, type: :int32)
  field(:parent_perm_id, 121, json_name: "parentPermId", proto3_optional: true, type: :int64)
  field(:use_price_mgmt_algo, 122, json_name: "usePriceMgmtAlgo", proto3_optional: true, type: :int32)
  field(:duration, 123, proto3_optional: true, type: :int32)
  field(:post_to_ats, 124, json_name: "postToAts", proto3_optional: true, type: :int32)
  field(:advanced_error_override, 125, json_name: "advancedErrorOverride", proto3_optional: true, type: :string)
  field(:manual_order_time, 126, json_name: "manualOrderTime", proto3_optional: true, type: :string)
  field(:min_trade_qty, 127, json_name: "minTradeQty", proto3_optional: true, type: :int32)
  field(:min_compete_size, 128, json_name: "minCompeteSize", proto3_optional: true, type: :int32)
  field(:compete_against_best_offset, 129, json_name: "competeAgainstBestOffset", proto3_optional: true, type: :double)
  field(:mid_offset_at_whole, 130, json_name: "midOffsetAtWhole", proto3_optional: true, type: :double)
  field(:mid_offset_at_half, 131, json_name: "midOffsetAtHalf", proto3_optional: true, type: :double)
  field(:customer_account, 132, json_name: "customerAccount", proto3_optional: true, type: :string)
  field(:professional_customer, 133, json_name: "professionalCustomer", proto3_optional: true, type: :bool)
  field(:bond_accrued_interest, 134, json_name: "bondAccruedInterest", proto3_optional: true, type: :string)
  field(:include_overnight, 135, json_name: "includeOvernight", proto3_optional: true, type: :bool)
  field(:manual_order_indicator, 136, json_name: "manualOrderIndicator", proto3_optional: true, type: :int32)
  field(:submitter, 137, proto3_optional: true, type: :string)
  field(:deactivate, 138, proto3_optional: true, type: :bool)
  field(:post_only, 139, json_name: "postOnly", proto3_optional: true, type: :bool)
  field(:allow_pre_open, 140, json_name: "allowPreOpen", proto3_optional: true, type: :bool)
  field(:ignore_open_auction, 141, json_name: "ignoreOpenAuction", proto3_optional: true, type: :bool)
  field(:seek_price_improvement, 142, json_name: "seekPriceImprovement", proto3_optional: true, type: :int32)
  field(:what_if_type, 143, json_name: "whatIfType", proto3_optional: true, type: :int32)
end
