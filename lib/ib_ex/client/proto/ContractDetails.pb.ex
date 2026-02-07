defmodule IbEx.Client.Proto.Protobuf.ContractDetails.SecIdListEntry do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ContractDetails.SecIdListEntry",
    map: true,
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule IbEx.Client.Proto.Protobuf.ContractDetails do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ContractDetails",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:market_name, 1, json_name: "marketName", proto3_optional: true, type: :string)
  field(:min_tick, 2, json_name: "minTick", proto3_optional: true, type: :string)
  field(:order_types, 3, json_name: "orderTypes", proto3_optional: true, type: :string)
  field(:valid_exchanges, 4, json_name: "validExchanges", proto3_optional: true, type: :string)
  field(:price_magnifier, 5, json_name: "priceMagnifier", proto3_optional: true, type: :int32)
  field(:under_con_id, 6, json_name: "underConId", proto3_optional: true, type: :int32)
  field(:long_name, 7, json_name: "longName", proto3_optional: true, type: :string)
  field(:contract_month, 8, json_name: "contractMonth", proto3_optional: true, type: :string)
  field(:industry, 9, proto3_optional: true, type: :string)
  field(:category, 10, proto3_optional: true, type: :string)
  field(:subcategory, 11, proto3_optional: true, type: :string)
  field(:time_zone_id, 12, json_name: "timeZoneId", proto3_optional: true, type: :string)
  field(:trading_hours, 13, json_name: "tradingHours", proto3_optional: true, type: :string)
  field(:liquid_hours, 14, json_name: "liquidHours", proto3_optional: true, type: :string)
  field(:ev_rule, 15, json_name: "evRule", proto3_optional: true, type: :string)
  field(:ev_multiplier, 16, json_name: "evMultiplier", proto3_optional: true, type: :double)

  field(:sec_id_list, 17,
    json_name: "secIdList",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.ContractDetails.SecIdListEntry,
    map: true
  )

  field(:agg_group, 18, json_name: "aggGroup", proto3_optional: true, type: :int32)
  field(:under_symbol, 19, json_name: "underSymbol", proto3_optional: true, type: :string)
  field(:under_sec_type, 20, json_name: "underSecType", proto3_optional: true, type: :string)
  field(:market_rule_ids, 21, json_name: "marketRuleIds", proto3_optional: true, type: :string)
  field(:real_expiration_date, 22, json_name: "realExpirationDate", proto3_optional: true, type: :string)
  field(:stock_type, 23, json_name: "stockType", proto3_optional: true, type: :string)
  field(:min_size, 24, json_name: "minSize", proto3_optional: true, type: :string)
  field(:size_increment, 25, json_name: "sizeIncrement", proto3_optional: true, type: :string)
  field(:suggested_size_increment, 26, json_name: "suggestedSizeIncrement", proto3_optional: true, type: :string)
  field(:fund_name, 27, json_name: "fundName", proto3_optional: true, type: :string)
  field(:fund_family, 28, json_name: "fundFamily", proto3_optional: true, type: :string)
  field(:fund_type, 29, json_name: "fundType", proto3_optional: true, type: :string)
  field(:fund_front_load, 30, json_name: "fundFrontLoad", proto3_optional: true, type: :string)
  field(:fund_back_load, 31, json_name: "fundBackLoad", proto3_optional: true, type: :string)
  field(:fund_back_load_time_interval, 32, json_name: "fundBackLoadTimeInterval", proto3_optional: true, type: :string)
  field(:fund_management_fee, 33, json_name: "fundManagementFee", proto3_optional: true, type: :string)
  field(:fund_closed, 34, json_name: "fundClosed", proto3_optional: true, type: :bool)
  field(:fund_closed_for_new_investors, 35, json_name: "fundClosedForNewInvestors", proto3_optional: true, type: :bool)
  field(:fund_closed_for_new_money, 36, json_name: "fundClosedForNewMoney", proto3_optional: true, type: :bool)
  field(:fund_notify_amount, 37, json_name: "fundNotifyAmount", proto3_optional: true, type: :string)

  field(:fund_minimum_initial_purchase, 38,
    json_name: "fundMinimumInitialPurchase",
    proto3_optional: true,
    type: :string
  )

  field(:fund_minimum_subsequent_purchase, 39,
    json_name: "fundMinimumSubsequentPurchase",
    proto3_optional: true,
    type: :string
  )

  field(:fund_blue_sky_states, 40, json_name: "fundBlueSkyStates", proto3_optional: true, type: :string)
  field(:fund_blue_sky_territories, 41, json_name: "fundBlueSkyTerritories", proto3_optional: true, type: :string)

  field(:fund_distribution_policy_indicator, 42,
    json_name: "fundDistributionPolicyIndicator",
    proto3_optional: true,
    type: :string
  )

  field(:fund_asset_type, 43, json_name: "fundAssetType", proto3_optional: true, type: :string)
  field(:cusip, 44, proto3_optional: true, type: :string)
  field(:issue_date, 45, json_name: "issueDate", proto3_optional: true, type: :string)
  field(:ratings, 46, proto3_optional: true, type: :string)
  field(:bond_type, 47, json_name: "bondType", proto3_optional: true, type: :string)
  field(:coupon, 48, proto3_optional: true, type: :double)
  field(:coupon_type, 49, json_name: "couponType", proto3_optional: true, type: :string)
  field(:convertible, 50, proto3_optional: true, type: :bool)
  field(:callable, 51, proto3_optional: true, type: :bool)
  field(:puttable, 52, proto3_optional: true, type: :bool)
  field(:desc_append, 53, json_name: "descAppend", proto3_optional: true, type: :string)
  field(:next_option_date, 54, json_name: "nextOptionDate", proto3_optional: true, type: :string)
  field(:next_option_type, 55, json_name: "nextOptionType", proto3_optional: true, type: :string)
  field(:next_option_partial, 56, json_name: "nextOptionPartial", proto3_optional: true, type: :bool)
  field(:bond_notes, 57, json_name: "bondNotes", proto3_optional: true, type: :string)

  field(:ineligibility_reason_list, 58,
    json_name: "ineligibilityReasonList",
    repeated: true,
    type: IbEx.Client.Proto.Protobuf.IneligibilityReason
  )

  field(:event_contract1, 59, json_name: "eventContract1", proto3_optional: true, type: :string)
  field(:event_contract_description1, 60, json_name: "eventContractDescription1", proto3_optional: true, type: :string)
  field(:event_contract_description2, 61, json_name: "eventContractDescription2", proto3_optional: true, type: :string)
  field(:min_algo_size, 62, json_name: "minAlgoSize", proto3_optional: true, type: :string)
end
