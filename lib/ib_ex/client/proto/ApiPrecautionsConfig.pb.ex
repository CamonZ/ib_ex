defmodule IbEx.Client.Proto.Protobuf.ApiPrecautionsConfig do
  @moduledoc false

  use Protobuf,
    full_name: "protobuf.ApiPrecautionsConfig",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:bypass_order_precautions, 1, json_name: "bypassOrderPrecautions", proto3_optional: true, type: :bool)
  field(:bypass_bond_warning, 2, json_name: "bypassBondWarning", proto3_optional: true, type: :bool)

  field(:bypass_negative_yield_confirmation, 3,
    json_name: "bypassNegativeYieldConfirmation",
    proto3_optional: true,
    type: :bool
  )

  field(:bypass_called_bond_warning, 4, json_name: "bypassCalledBondWarning", proto3_optional: true, type: :bool)

  field(:bypass_same_action_pair_trade_warning, 5,
    json_name: "bypassSameActionPairTradeWarning",
    proto3_optional: true,
    type: :bool
  )

  field(:bypass_flagged_accounts_warning, 6,
    json_name: "bypassFlaggedAccountsWarning",
    proto3_optional: true,
    type: :bool
  )

  field(:bypass_price_based_volatility_warning, 7,
    json_name: "bypassPriceBasedVolatilityWarning",
    proto3_optional: true,
    type: :bool
  )

  field(:bypass_redirect_order_warning, 8, json_name: "bypassRedirectOrderWarning", proto3_optional: true, type: :bool)
  field(:bypass_no_overfill_protection, 9, json_name: "bypassNoOverfillProtection", proto3_optional: true, type: :bool)

  field(:bypass_route_marketable_to_bbo, 10,
    json_name: "bypassRouteMarketableToBBO",
    proto3_optional: true,
    type: :bool
  )
end
