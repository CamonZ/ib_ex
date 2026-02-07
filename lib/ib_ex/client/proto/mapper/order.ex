defmodule IbEx.Client.Proto.Mapper.Order do
  @moduledoc """
  Maps between `IbEx.Client.Types.Order` domain structs and
  `IbEx.Client.Proto.Protobuf.Order` proto structs.

  The domain Order nests params into sub-structs (ScaleOrderParams, HedgeOrderParams,
  AlgoOrderParams, etc.) while the proto Order uses flat fields. This mapper handles
  the flattening (to_proto) and unflattening (from_proto) of those nested structures.

  Sentinel values:
  - :unset_double in domain -> nil in proto
  - :unset_integer in domain -> nil in proto
  - nil in proto -> :unset_double / :unset_integer in domain (per field)
  """

  alias IbEx.Client.Types.Order, as: DomainOrder

  alias IbEx.Client.Types.Order.{
    ShortSaleParams,
    FinancialAdvisorParams,
    VolatilityOrderParams,
    DeltaNeutralParams,
    HedgeOrderParams,
    ScaleOrderParams,
    ClearingInfoParams,
    AlgoOrderParams,
    PegToBenchmarkOrderParams,
    OrderConditionsParams,
    SoftDollarTierParams
  }

  alias IbEx.Client.Proto.Protobuf.Order, as: ProtoOrder
  alias IbEx.Client.Proto.Protobuf.SoftDollarTier, as: ProtoSoftDollarTier
  alias IbEx.Client.Proto.Protobuf.OrderCondition, as: ProtoOrderCondition
  alias IbEx.Client.Proto.Mapper.Helpers
  alias IbEx.Client.Utils

  @doc """
  Converts a domain Order to a proto Order.

  Flattens nested sub-structs into flat proto fields and translates
  types (Decimal -> double/string, sentinels -> nil).
  """
  @spec to_proto(DomainOrder.t()) :: ProtoOrder.t()
  def to_proto(%DomainOrder{} = order) do
    %ProtoOrder{
      # Order identifiers
      client_id: order.api_client_id,
      order_id: order.api_client_order_id,
      perm_id: order.host_order_id,
      parent_id: order.parent_id,

      # Main order fields
      action: order.action,
      total_quantity: Utils.to_string_value(order.total_quantity, :nullable),
      display_size: order.display_size,
      order_type: order.order_type,
      lmt_price: Utils.to_float(order.limit_price, :nullable),
      aux_price: Utils.to_float(order.aux_price, :nullable),
      tif: Utils.to_string_value(order.time_in_force, :nullable),
      account: order.account,
      settling_firm: order.settling_firm,

      # Clearing (from ClearingInfoParams)
      clearing_account: get_clearing_field(order, :clearing_account),
      clearing_intent: get_clearing_field(order, :clearing_intent),

      # Boolean/int fields
      all_or_none: order.all_or_none,
      block_order: order.block_order,
      hidden: order.hidden,
      outside_rth: order.outside_rth,
      sweep_to_fill: order.sweep_to_fill,
      percent_offset: Utils.to_float(order.percent_offset, :nullable),
      trailing_percent: Utils.to_float(order.trailing_percent, :nullable),
      trail_stop_price: Utils.to_float(order.trail_stop_price, :nullable),
      min_qty: order.min_quantity,
      good_after_time: order.good_after_time,
      good_till_date: order.good_till_date,
      oca_group: order.oca_group_identifier,
      order_ref: order.order_ref,
      rule80_a: Utils.to_string_value(order.rule_80a, :nullable),
      oca_type: order.oca_type,
      trigger_method: order.trigger_method,
      active_start_time: order.active_start_time,
      active_stop_time: order.active_stop_time,

      # Financial advisor (from FinancialAdvisorParams)
      fa_group: get_fa_field(order, :group_identifier),
      fa_method: get_fa_field(order, :method),
      fa_percentage: get_fa_field(order, :percentage),

      # Volatility order (from VolatilityOrderParams)
      volatility: get_volatility_field(order, :volatility),
      volatility_type: get_volatility_field(order, :volatility_type),
      continuous_update: order.continuous_update,
      reference_price_type: order.reference_price_type,

      # Delta neutral (from DeltaNeutralParams)
      delta_neutral_order_type: get_dn_field(order, :order_type),
      delta_neutral_aux_price: get_dn_double_field(order, :aux_price),
      delta_neutral_con_id: get_dn_field(order, :conid),
      delta_neutral_open_close: get_dn_field(order, :open_close),
      delta_neutral_short_sale: get_dn_field(order, :short_sale),
      delta_neutral_short_sale_slot: get_dn_field(order, :short_sale_slot),
      delta_neutral_designated_location: get_dn_field(order, :designated_location),
      delta_neutral_settling_firm: get_dn_field(order, :settling_firm),
      delta_neutral_clearing_account: get_dn_field(order, :clearing_account),
      delta_neutral_clearing_intent: get_dn_field(order, :clearing_intent),

      # Scale order (from ScaleOrderParams)
      scale_init_level_size: get_scale_field(order, :init_level_size),
      scale_subs_level_size: get_scale_field(order, :subs_level_size),
      scale_price_increment: get_scale_double_field(order, :price_increment),
      scale_price_adjust_value: get_scale_double_field(order, :price_adjust_value),
      scale_price_adjust_interval: get_scale_field(order, :price_adjust_interval),
      scale_profit_offset: get_scale_double_field(order, :profit_offset),
      scale_auto_reset: get_scale_field(order, :auto_reset),
      scale_init_position: get_scale_field(order, :init_position),
      scale_init_fill_qty: get_scale_field(order, :init_fill_quantity),
      scale_random_percent: get_scale_field(order, :random_percent),
      scale_table: get_scale_field(order, :table),

      # Hedge order (from HedgeOrderParams)
      hedge_type: get_hedge_field(order, :hedge_type),
      hedge_param: get_hedge_field(order, :hedge_param),

      # Algo order (from AlgoOrderParams)
      algo_strategy: get_algo_field(order, :algo_strategy),
      algo_params: algo_params_to_map(order),
      algo_id: get_algo_field(order, :algo_id),

      # Smart combo routing
      smart_combo_routing_params: smart_combo_to_map(order),

      # Misc
      what_if: order.what_if_info_and_commission,
      transmit: order.transmit,
      override_percentage_constraints: order.override_percentage_constraints,
      open_close: Utils.to_string_value(order.open_close, :nullable),
      origin: order.origin,

      # Short sale (from ShortSaleParams)
      short_sale_slot: get_short_sale_field(order, :short_sale_slot),
      designated_location: get_short_sale_field(order, :designated_location),
      exempt_code: get_short_sale_field(order, :exempt_code),
      discretionary_amt: Utils.to_float(order.discretionary_amount, :nullable),
      opt_out_smart_routing: order.opt_out_smart_routing,
      starting_price: Utils.to_float(order.starting_price, :nullable),
      stock_ref_price: Utils.to_float(order.stock_reference_price, :nullable),
      delta: Utils.to_float(order.delta, :nullable),
      stock_range_lower: Utils.to_float(order.stock_range_lower, :nullable),
      stock_range_upper: Utils.to_float(order.stock_range_upper, :nullable),
      not_held: order.not_held,

      # Misc options (TagValueList -> map)
      order_misc_options: Helpers.tag_value_list_to_map(order.misc_options),
      solicited: order.solicited,
      randomize_size: order.randomize_size,
      randomize_price: order.randomize_price,

      # Peg to benchmark (from PegToBenchmarkOrderParams)
      reference_contract_id: get_peg_bench_field(order, :reference_contract_id),
      pegged_change_amount: get_peg_bench_double_field(order, :pegged_change_amount),
      is_pegged_change_amount_decrease: get_peg_bench_field(order, :is_pegged_change_amount_decrease),
      reference_change_amount: get_peg_bench_double_field(order, :reference_change_amoung),
      reference_exchange_id: get_peg_bench_field(order, :reference_exchange_id),

      # Order conditions (from OrderConditionsParams)
      conditions: conditions_to_proto(order.order_conditions_params),
      conditions_cancel_order: get_conditions_field(order, :conditions_cancel_order),
      conditions_ignore_rth: get_conditions_field(order, :conditions_ignore_rth),

      # Adjusted order fields (sentinel doubles)
      adjusted_order_type: order.adjusted_order_type,
      trigger_price: Utils.to_float(order.trigger_price, :nullable),
      adjusted_stop_price: Utils.to_float(order.adjusted_stop_price, :nullable),
      adjusted_stop_limit_price: Utils.to_float(order.adjusted_stop_limit_price, :nullable),
      adjusted_trailing_amount: Utils.to_float(order.adjusted_trailing_amount, :nullable),
      adjustable_trailing_unit: order.adjustable_trailing_unit,
      lmt_price_offset: Utils.to_float(order.limit_price_offset, :nullable),
      model_code: order.model_code,
      ext_operator: order.ext_operator,

      # Soft dollar tier (from SoftDollarTierParams)
      soft_dollar_tier: soft_dollar_tier_to_proto(order),
      cash_qty: Utils.to_float(order.cash_quantity, :nullable),
      mifid2_decision_maker: order.mifid2_decision_maker,
      mifid2_decision_algo: order.mifid2_decision_algo,
      mifid2_execution_trader: order.mifid2_execution_trader,
      mifid2_execution_algo: order.mifid2_execution_algo,
      dont_use_auto_price_for_hedge: order.dont_use_autoprice_for_hedge,
      is_oms_container: order.is_oms_container,
      discretionary_up_to_limit_price: order.discretionary_up_to_limit_price,
      auto_cancel_date: order.auto_cancel_date,
      filled_quantity: Utils.to_string_value(order.filled_quantity, :nullable),
      ref_futures_con_id: order.ref_futures_con_id,
      auto_cancel_parent: order.auto_cancel_parent,
      shareholder: order.shareholder,
      imbalance_only: order.imbalance_only,
      route_marketable_to_bbo: Utils.to_bool(order.route_marketable_to_bbo, :nullable) |> bool_to_int(),
      parent_perm_id: order.parent_perm_id,
      use_price_mgmt_algo: use_price_mgmt_algo_to_proto(order.use_price_management_algo),
      duration: Utils.to_integer(order.duration, :nullable),
      post_to_ats: Utils.to_integer(order.post_to_ats, :nullable),
      advanced_error_override: order.advanced_error_override,
      manual_order_time: order.manual_order_time,
      min_trade_qty: order.min_trade_quantity,
      min_compete_size: order.min_compete_size,
      compete_against_best_offset: Utils.to_float(order.compete_against_best_offset, :nullable),
      mid_offset_at_whole: Utils.to_float(order.mid_offset_at_whole, :nullable),
      mid_offset_at_half: Utils.to_float(order.mid_offset_at_half, :nullable),
      customer_account: order.customer_account,
      professional_customer: order.professional_customer,
      bond_accrued_interest: order.bond_accrued_interest,
      include_overnight: order.include_overnight,
      manual_order_indicator: Utils.to_integer(order.manual_order_indicator, :nullable),
      submitter: order.submitter,
      deactivate: order.deactivate,
      post_only: order.post_only,
      allow_pre_open: order.allow_pre_open,
      ignore_open_auction: order.ignore_open_auction,
      seek_price_improvement: Utils.to_bool(order.seek_price_improvement, :nullable) |> bool_to_int(),
      what_if_type: order.what_if_type
    }
  end

  @doc """
  Converts a proto Order to a domain Order.

  Unflattens flat proto fields back into nested domain sub-structs and translates
  types (double/string -> Decimal, nil -> sentinels).
  """
  @spec from_proto(ProtoOrder.t()) :: DomainOrder.t()
  def from_proto(%ProtoOrder{} = proto) do
    DomainOrder.new(%{
      # Order identifiers
      api_client_id: proto.client_id,
      api_client_order_id: proto.order_id,
      host_order_id: proto.perm_id,
      parent_id: proto.parent_id || 0,

      # Main order fields
      action: proto.action,
      total_quantity: Utils.to_integer(proto.total_quantity, :nullable),
      order_type: proto.order_type,
      limit_price: Utils.to_decimal(proto.lmt_price, :nullable),
      aux_price: Utils.to_decimal(proto.aux_price, :nullable),
      time_in_force: proto.tif,
      account: proto.account,
      settling_firm: proto.settling_firm,
      all_or_none: proto.all_or_none || false,
      block_order: proto.block_order || false,
      hidden: proto.hidden || false,
      outside_rth: proto.outside_rth || false,
      sweep_to_fill: proto.sweep_to_fill || false,
      percent_offset: Utils.to_decimal(proto.percent_offset, :nullable),
      trailing_percent: Utils.to_decimal(proto.trailing_percent, :nullable),
      trail_stop_price: Utils.to_decimal(proto.trail_stop_price, :nullable),
      min_quantity: proto.min_qty,
      good_after_time: proto.good_after_time,
      good_till_date: proto.good_till_date,
      oca_group_identifier: proto.oca_group,
      order_ref: proto.order_ref,
      rule_80a: proto.rule80_a,
      oca_type: proto.oca_type || 0,
      trigger_method: proto.trigger_method || 0,
      active_start_time: proto.active_start_time,
      active_stop_time: proto.active_stop_time,
      display_size: proto.display_size || 0,
      open_close: proto.open_close,
      origin: proto.origin || 0,
      transmit: if(is_nil(proto.transmit), do: true, else: proto.transmit),

      # Nested sub-structs rebuilt from flat fields
      fa_params: %{
        group_identifier: proto.fa_group,
        method: proto.fa_method,
        percentage: proto.fa_percentage
      },
      short_sale_params: %{
        short_sale_slot: proto.short_sale_slot || 0,
        designated_location: proto.designated_location,
        exempt_code: proto.exempt_code || -1
      },
      volatility_order_params: %{
        volatility: Utils.to_decimal(proto.volatility, :nullable),
        volatility_type: proto.volatility_type
      },
      delta_neutral_params: %{
        order_type: proto.delta_neutral_order_type,
        aux_price: Utils.to_decimal(proto.delta_neutral_aux_price, :nullable),
        conid: proto.delta_neutral_con_id || 0,
        settling_firm: proto.delta_neutral_settling_firm,
        clearing_account: proto.delta_neutral_clearing_account,
        clearing_intent: proto.delta_neutral_clearing_intent,
        open_close: proto.delta_neutral_open_close,
        short_sale: proto.delta_neutral_short_sale || false,
        short_sale_slot: proto.delta_neutral_short_sale_slot || 0,
        designated_location: proto.delta_neutral_designated_location
      },
      scale_order_params: %{
        init_level_size: proto.scale_init_level_size,
        subs_level_size: proto.scale_subs_level_size,
        price_increment: Utils.to_decimal(proto.scale_price_increment, :nullable),
        price_adjust_value: Utils.to_decimal(proto.scale_price_adjust_value, :nullable),
        price_adjust_interval: proto.scale_price_adjust_interval,
        profit_offset: Utils.to_decimal(proto.scale_profit_offset, :nullable),
        auto_reset: proto.scale_auto_reset || false,
        init_position: proto.scale_init_position,
        init_fill_quantity: proto.scale_init_fill_qty,
        random_percent: proto.scale_random_percent || false,
        table: proto.scale_table
      },
      hedge_order_params: %{
        hedge_type: proto.hedge_type,
        hedge_param: proto.hedge_param
      },
      algo_params: %{
        algo_strategy: proto.algo_strategy,
        algo_params: Helpers.map_to_tag_value_list(proto.algo_params),
        algo_id: proto.algo_id
      },
      clearing_params: %{
        clearing_account: proto.clearing_account,
        clearing_intent: proto.clearing_intent
      },
      smart_combo_routing_params: %{
        params: Helpers.map_to_tag_value_list(proto.smart_combo_routing_params)
      },
      peg_to_bench_params: %{
        reference_contract_id: proto.reference_contract_id || 0,
        is_pegged_change_amount_decrease: proto.is_pegged_change_amount_decrease || false,
        pegged_change_amount: Utils.to_decimal(proto.pegged_change_amount, :nullable) || Decimal.new("0.0"),
        reference_change_amoung: Utils.to_decimal(proto.reference_change_amount, :nullable) || Decimal.new("0.0"),
        reference_exchange_id: proto.reference_exchange_id
      },
      order_conditions_params: conditions_from_proto_map(proto),
      soft_dollar_tier_params: soft_dollar_tier_from_proto_map(proto),
      model_code: proto.model_code,
      continuous_update: proto.continuous_update || false,
      reference_price_type: proto.reference_price_type,
      discretionary_amount: Utils.to_decimal(proto.discretionary_amt, :nullable) || 0,
      opt_out_smart_routing: proto.opt_out_smart_routing || false,
      starting_price: Utils.to_decimal(proto.starting_price, :nullable),
      stock_reference_price: Utils.to_decimal(proto.stock_ref_price, :nullable),
      delta: Utils.to_decimal(proto.delta, :nullable),
      stock_range_lower: Utils.to_decimal(proto.stock_range_lower, :nullable),
      stock_range_upper: Utils.to_decimal(proto.stock_range_upper, :nullable),
      not_held: proto.not_held || false,
      what_if_info_and_commission: proto.what_if || false,
      override_percentage_constraints: proto.override_percentage_constraints || false,
      misc_options: Helpers.map_to_tag_value_list(proto.order_misc_options),
      solicited: proto.solicited || false,
      randomize_size: proto.randomize_size || false,
      randomize_price: proto.randomize_price || false,

      # Adjusted order fields (nil -> sentinel)
      adjusted_order_type: proto.adjusted_order_type,
      trigger_price: Utils.to_decimal(proto.trigger_price, :nullable) || :unset_double,
      adjusted_stop_price: Utils.to_decimal(proto.adjusted_stop_price, :nullable) || :unset_double,
      adjusted_stop_limit_price: Utils.to_decimal(proto.adjusted_stop_limit_price, :nullable) || :unset_double,
      adjusted_trailing_amount: Utils.to_decimal(proto.adjusted_trailing_amount, :nullable) || :unset_double,
      adjustable_trailing_unit: proto.adjustable_trailing_unit || 0,
      limit_price_offset: Utils.to_decimal(proto.lmt_price_offset, :nullable) || :unset_double,
      ext_operator: proto.ext_operator,
      cash_quantity: Utils.to_decimal(proto.cash_qty, :nullable) || :unset_double,
      mifid2_decision_maker: proto.mifid2_decision_maker,
      mifid2_decision_algo: proto.mifid2_decision_algo,
      mifid2_execution_trader: proto.mifid2_execution_trader,
      mifid2_execution_algo: proto.mifid2_execution_algo,
      dont_use_autoprice_for_hedge: proto.dont_use_auto_price_for_hedge || false,
      is_oms_container: proto.is_oms_container || false,
      discretionary_up_to_limit_price: proto.discretionary_up_to_limit_price || false,
      use_price_management_algo: use_price_mgmt_algo_from_proto(proto.use_price_mgmt_algo),
      duration: Utils.to_integer(proto.duration, :nullable) || :unset_integer,
      post_to_ats: Utils.to_integer(proto.post_to_ats, :nullable) || :unset_integer,
      auto_cancel_parent: proto.auto_cancel_parent || false,
      advanced_error_override: proto.advanced_error_override,
      manual_order_time: proto.manual_order_time,
      min_trade_quantity: proto.min_trade_qty,
      min_compete_size: proto.min_compete_size,
      compete_against_best_offset: Utils.to_decimal(proto.compete_against_best_offset, :nullable),
      mid_offset_at_whole: Utils.to_decimal(proto.mid_offset_at_whole, :nullable),
      mid_offset_at_half: Utils.to_decimal(proto.mid_offset_at_half, :nullable),
      customer_account: proto.customer_account,
      professional_customer: proto.professional_customer || false,
      external_user_id: nil,
      manual_order_indicator: Utils.to_integer(proto.manual_order_indicator, :nullable) || :unset_integer,
      bond_accrued_interest: proto.bond_accrued_interest,
      include_overnight: proto.include_overnight || false,
      submitter: proto.submitter,
      post_only: proto.post_only || false,
      allow_pre_open: proto.allow_pre_open || false,
      ignore_open_auction: proto.ignore_open_auction || false,
      deactivate: proto.deactivate || false,
      seek_price_improvement: proto.seek_price_improvement != 0 && proto.seek_price_improvement != nil,
      what_if_type: proto.what_if_type,
      auto_cancel_date: proto.auto_cancel_date,
      filled_quantity: Utils.to_decimal(proto.filled_quantity, :nullable),
      ref_futures_con_id: proto.ref_futures_con_id,
      shareholder: proto.shareholder,
      imbalance_only: proto.imbalance_only || false,
      route_marketable_to_bbo: Utils.to_bool(proto.route_marketable_to_bbo, :nullable) || false,
      parent_perm_id: proto.parent_perm_id
    })
  end

  # --- Private helpers for nested struct field access ---

  defp get_fa_field(%DomainOrder{fa_params: %FinancialAdvisorParams{} = fa}, field),
    do: Map.get(fa, field)

  defp get_fa_field(_, _), do: nil

  defp get_short_sale_field(%DomainOrder{short_sale_params: %ShortSaleParams{} = ss}, field),
    do: Map.get(ss, field)

  defp get_short_sale_field(_, _), do: nil

  defp get_volatility_field(%DomainOrder{volatility_order_params: %VolatilityOrderParams{} = vop}, :volatility),
    do: Utils.to_float(vop.volatility, :nullable)

  defp get_volatility_field(%DomainOrder{volatility_order_params: %VolatilityOrderParams{} = vop}, field),
    do: Map.get(vop, field)

  defp get_volatility_field(_, _), do: nil

  defp get_dn_field(%DomainOrder{delta_neutral_params: %DeltaNeutralParams{} = dn}, field),
    do: Map.get(dn, field)

  defp get_dn_field(_, _), do: nil

  defp get_dn_double_field(%DomainOrder{delta_neutral_params: %DeltaNeutralParams{} = dn}, field),
    do: Utils.to_float(Map.get(dn, field), :nullable)

  defp get_dn_double_field(_, _), do: nil

  defp get_scale_field(%DomainOrder{scale_order_params: %ScaleOrderParams{} = sp}, field),
    do: Map.get(sp, field)

  defp get_scale_field(_, _), do: nil

  defp get_scale_double_field(%DomainOrder{scale_order_params: %ScaleOrderParams{} = sp}, field),
    do: Utils.to_float(Map.get(sp, field), :nullable)

  defp get_scale_double_field(_, _), do: nil

  defp get_hedge_field(%DomainOrder{hedge_order_params: %HedgeOrderParams{} = hp}, field),
    do: Map.get(hp, field)

  defp get_hedge_field(_, _), do: nil

  defp get_algo_field(%DomainOrder{algo_params: %AlgoOrderParams{} = ap}, field),
    do: Map.get(ap, field)

  defp get_algo_field(_, _), do: nil

  defp get_peg_bench_field(%DomainOrder{peg_to_bench_params: %PegToBenchmarkOrderParams{} = pb}, field),
    do: Map.get(pb, field)

  defp get_peg_bench_field(_, _), do: nil

  defp get_peg_bench_double_field(%DomainOrder{peg_to_bench_params: %PegToBenchmarkOrderParams{} = pb}, field),
    do: Utils.to_float(Map.get(pb, field), :nullable)

  defp get_peg_bench_double_field(_, _), do: nil

  defp get_conditions_field(%DomainOrder{order_conditions_params: %OrderConditionsParams{} = ocp}, field),
    do: Map.get(ocp, field)

  defp get_conditions_field(_, _), do: nil

  defp get_clearing_field(%DomainOrder{clearing_params: %ClearingInfoParams{} = cp}, field),
    do: Map.get(cp, field)

  defp get_clearing_field(_, _), do: nil

  # --- Algo params to/from map ---

  defp algo_params_to_map(%DomainOrder{algo_params: %AlgoOrderParams{algo_params: params}})
       when is_list(params) do
    Helpers.tag_value_list_to_map(params)
  end

  defp algo_params_to_map(_), do: %{}

  # --- Smart combo routing to/from map ---

  defp smart_combo_to_map(%DomainOrder{
         smart_combo_routing_params: %IbEx.Client.Types.Order.SmartComboRoutingParams{params: params}
       })
       when is_list(params) do
    Helpers.tag_value_list_to_map(params)
  end

  defp smart_combo_to_map(_), do: %{}

  # --- Conditions to/from proto ---

  defp conditions_to_proto(%OrderConditionsParams{conditions: conditions}) when is_list(conditions) do
    Enum.map(conditions, fn condition ->
      if function_exported?(condition.__struct__, :to_proto, 1) do
        condition.__struct__.to_proto(condition)
      else
        %ProtoOrderCondition{}
      end
    end)
  end

  defp conditions_to_proto(_), do: []

  defp conditions_from_proto_map(%ProtoOrder{conditions: conditions}) when is_list(conditions) do
    %{
      conditions: conditions,
      conditions_cancel_order: false,
      conditions_ignore_rth: false
    }
  end

  defp conditions_from_proto_map(%ProtoOrder{} = proto) do
    %{
      conditions: [],
      conditions_cancel_order: proto.conditions_cancel_order || false,
      conditions_ignore_rth: proto.conditions_ignore_rth || false
    }
  end

  # --- Soft dollar tier to/from proto ---

  defp soft_dollar_tier_to_proto(%DomainOrder{soft_dollar_tier_params: %SoftDollarTierParams{} = sdt}) do
    %ProtoSoftDollarTier{
      name: sdt.name,
      value: Utils.to_string_value(sdt.value, :nullable),
      display_name: sdt.display_name
    }
  end

  defp soft_dollar_tier_to_proto(_), do: nil

  defp soft_dollar_tier_from_proto_map(%ProtoOrder{soft_dollar_tier: %ProtoSoftDollarTier{} = sdt}) do
    %{
      name: sdt.name,
      value: sdt.value,
      display_name: sdt.display_name
    }
  end

  defp soft_dollar_tier_from_proto_map(_), do: %{}

  # --- use_price_management_algo: bool|nil <-> int (0=false, 1=true, nil=unset) ---

  defp use_price_mgmt_algo_to_proto(nil), do: nil
  defp use_price_mgmt_algo_to_proto(true), do: 1
  defp use_price_mgmt_algo_to_proto(false), do: 0

  defp use_price_mgmt_algo_from_proto(nil), do: nil
  defp use_price_mgmt_algo_from_proto(0), do: false
  defp use_price_mgmt_algo_from_proto(1), do: true
  defp use_price_mgmt_algo_from_proto(_), do: nil

  # --- bool_to_int helper for route_marketable_to_bbo / seek_price_improvement ---

  defp bool_to_int(nil), do: nil
  defp bool_to_int(true), do: 1
  defp bool_to_int(false), do: 0

  # removed: to_string_or_nil, decimal_or_int_to_string, decimal_or_value_to_string,
  #          string_to_int_or_nil, string_to_decimal_or_nil — replaced by Utils functions
end
