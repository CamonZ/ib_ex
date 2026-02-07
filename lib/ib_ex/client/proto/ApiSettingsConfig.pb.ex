defmodule IbEx.Client.Proto.Protobuf.ApiSettingsConfig do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ApiSettingsConfig",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:read_only_api, 1, json_name: "readOnlyApi", proto3_optional: true, type: :bool)

  field(:total_quantity_for_mutual_funds, 2,
    json_name: "totalQuantityForMutualFunds",
    proto3_optional: true,
    type: :bool
  )

  field(:download_open_orders_on_connection, 3,
    json_name: "downloadOpenOrdersOnConnection",
    proto3_optional: true,
    type: :bool
  )

  field(:include_virtual_fx_positions, 4, json_name: "includeVirtualFxPositions", proto3_optional: true, type: :bool)
  field(:prepare_daily_pn_l, 5, json_name: "prepareDailyPnL", proto3_optional: true, type: :bool)

  field(:send_status_updates_for_volatility_orders, 6,
    json_name: "sendStatusUpdatesForVolatilityOrders",
    proto3_optional: true,
    type: :bool
  )

  field(:encode_api_messages, 7, json_name: "encodeApiMessages", proto3_optional: true, type: :string)
  field(:socket_port, 8, json_name: "socketPort", proto3_optional: true, type: :int32)
  field(:use_negative_auto_range, 9, json_name: "useNegativeAutoRange", proto3_optional: true, type: :bool)
  field(:create_api_message_log_file, 10, json_name: "createApiMessageLogFile", proto3_optional: true, type: :bool)

  field(:include_market_data_in_log_file, 11,
    json_name: "includeMarketDataInLogFile",
    proto3_optional: true,
    type: :bool
  )

  field(:expose_trading_schedule_to_api, 12,
    json_name: "exposeTradingScheduleToApi",
    proto3_optional: true,
    type: :bool
  )

  field(:split_insured_deposit_from_cash_balance, 13,
    json_name: "splitInsuredDepositFromCashBalance",
    proto3_optional: true,
    type: :bool
  )

  field(:send_zero_positions_for_today_only, 14,
    json_name: "sendZeroPositionsForTodayOnly",
    proto3_optional: true,
    type: :bool
  )

  field(:let_api_account_requests_switch_subscription, 15,
    json_name: "letApiAccountRequestsSwitchSubscription",
    proto3_optional: true,
    type: :bool
  )

  field(:use_account_groups_with_allocation_methods, 16,
    json_name: "useAccountGroupsWithAllocationMethods",
    proto3_optional: true,
    type: :bool
  )

  field(:logging_level, 17, json_name: "loggingLevel", proto3_optional: true, type: :string)
  field(:master_client_id, 18, json_name: "masterClientId", proto3_optional: true, type: :int32)
  field(:bulk_data_timeout, 19, json_name: "bulkDataTimeout", proto3_optional: true, type: :int32)
  field(:component_exch_separator, 20, json_name: "componentExchSeparator", proto3_optional: true, type: :string)

  field(:show_forex_data_in1_10_pips, 21,
    json_name: "showForexDataIn1_10Pips",
    proto3_optional: true,
    type: :bool,
    json_name: "showForexDataIn110Pips"
  )

  field(:allow_forex_trading_in1_10_pips, 22,
    json_name: "allowForexTradingIn1_10Pips",
    proto3_optional: true,
    type: :bool,
    json_name: "allowForexTradingIn110Pips"
  )

  field(:round_account_values_to_nearest_whole_number, 23,
    json_name: "roundAccountValuesToNearestWholeNumber",
    proto3_optional: true,
    type: :bool
  )

  field(:send_market_data_in_lots_for_us_stocks, 24,
    json_name: "sendMarketDataInLotsForUsStocks",
    proto3_optional: true,
    type: :bool
  )

  field(:show_advanced_order_reject_in_ui, 25,
    json_name: "showAdvancedOrderRejectInUi",
    proto3_optional: true,
    type: :bool
  )

  field(:reject_messages_above_max_rate, 26,
    json_name: "rejectMessagesAboveMaxRate",
    proto3_optional: true,
    type: :bool
  )

  field(:maintain_connection_on_incorrect_fields, 27,
    json_name: "maintainConnectionOnIncorrectFields",
    proto3_optional: true,
    type: :bool
  )

  field(:compatibility_mode_nasdaq_stocks, 28,
    json_name: "compatibilityModeNasdaqStocks",
    proto3_optional: true,
    type: :bool
  )

  field(:send_instrument_timezone, 29, json_name: "sendInstrumentTimezone", proto3_optional: true, type: :string)

  field(:send_forex_data_in_compatibility_mode, 30,
    json_name: "sendForexDataInCompatibilityMode",
    proto3_optional: true,
    type: :bool
  )

  field(:maintain_and_resubmit_orders_on_reconnect, 31,
    json_name: "maintainAndResubmitOrdersOnReconnect",
    proto3_optional: true,
    type: :bool
  )

  field(:historical_data_max_size, 32, json_name: "historicalDataMaxSize", proto3_optional: true, type: :int32)

  field(:auto_report_netting_event_contract_trades, 33,
    json_name: "autoReportNettingEventContractTrades",
    proto3_optional: true,
    type: :bool
  )

  field(:option_exercise_request_type, 34, json_name: "optionExerciseRequestType", proto3_optional: true, type: :string)
  field(:allow_localhost_only, 35, json_name: "allowLocalhostOnly", proto3_optional: true, type: :bool)
  field(:trusted_i_ps, 36, json_name: "trustedIPs", repeated: true, type: :string)
end
