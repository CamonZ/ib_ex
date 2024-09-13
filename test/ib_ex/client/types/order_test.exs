defmodule IbEx.Client.Types.OrderTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    ShortSaleParams,
    FinancialAdvisorParams,
    VolatilityOrderParams,
    HedgeOrderParams,
    ScaleOrderParams,
    ClearingInfoParams,
    AlgoOrderParams,
    PegToBenchmarkOrderParams,
    OrderConditionsParams,
    SoftDollarTierParams,
    SmartComboRoutingParams
  }

  alias IbEx.Client.Types.{Order, TagValue}

  describe "new/1" do
    test "creates an Order with valid attributes" do
      params = %{
        api_client_order_id: 1,
        api_client_id: 2,
        host_order_id: 3,
        action: "BUY",
        total_quantity: 10,
        order_type: "IBALGO"
      }

      assert Order.new(params) == %Order{
               api_client_order_id: 1,
               api_client_id: 2,
               host_order_id: 3,
               action: "BUY",
               total_quantity: 10,
               order_type: "IBALGO",
               limit_price: nil,
               aux_price: nil,
               time_in_force: nil,
               oca_group_identifier: nil,
               account: nil,
               open_close: nil,
               origin: 0,
               order_ref: nil,
               transmit: true,
               parent_id: 0,
               block_order: false,
               sweep_to_fill: false,
               display_size: 0,
               trigger_method: 0,
               outside_rth: false,
               hidden: false,
               combo_legs: [],
               smart_combo_routing_params: SmartComboRoutingParams.new(),
               discretionary_amount: 0,
               good_after_time: nil,
               good_till_date: nil,
               fa_params: FinancialAdvisorParams.new(),
               model_code: nil,
               short_sale_params: ShortSaleParams.new(),
               oca_type: 0,
               rule_80a: nil,
               settling_firm: nil,
               all_or_none: false,
               min_quantity: nil,
               percent_offset: nil,
               auction_strategy: 0,
               starting_price: nil,
               stock_reference_price: nil,
               delta: nil,
               stock_range_lower: nil,
               stock_range_upper: nil,
               override_percentage_constraints: false,
               volatility_order_params: VolatilityOrderParams.new(),
               continuous_update: false,
               reference_price_type: nil,
               trail_stop_price: nil,
               trailing_percent: nil,
               scale_order_params: ScaleOrderParams.new(),
               hedge_order_params: HedgeOrderParams.new(),
               opt_out_smart_routing: false,
               clearing_params: ClearingInfoParams.new(),
               not_held: false,
               algo_params: AlgoOrderParams.new(),
               what_if_info_and_commission: false,
               misc_options: [],
               solicited: false,
               randomize_size: false,
               randomize_price: false,
               peg_to_bench_params: PegToBenchmarkOrderParams.new(),
               order_conditions_params: OrderConditionsParams.new(),
               adjusted_order_type: nil,
               trigger_price: :unset_double,
               limit_price_offset: :unset_double,
               adjusted_stop_price: :unset_double,
               adjusted_stop_limit_price: :unset_double,
               adjusted_trailing_amount: :unset_double,
               adjustable_trailing_unit: 0,
               ext_operator: nil,
               soft_dollar_tier_params: SoftDollarTierParams.new(),
               cash_quantity: :unset_double,
               mifid2_decision_maker: nil,
               mifid2_decision_algo: nil,
               mifid2_execution_trader: nil,
               mifid2_execution_algo: nil,
               dont_use_autoprice_for_hedge: false,
               is_oms_container: false,
               discretionary_up_to_limit_price: false,
               use_price_management_algo: nil,
               duration: :unset_integer,
               post_to_ats: :unset_integer,
               auto_cancel_parent: false,
               advanced_error_override: nil,
               manual_order_time: nil,
               min_trade_quantity: nil,
               min_compete_size: nil,
               compete_against_best_offset: nil,
               mid_offset_at_whole: nil,
               mid_offset_at_half: nil,
               customer_account: nil
             }
    end
  end

  describe "serialize/1" do
    test "serializes first batch of parameters for RequestCreateOrder" do
      params = %{
        action: "BUY",
        total_quantity: 1,
        order_type: "IBALGO",
        limit_price: Decimal.new("2"),
        aux_price: Decimal.new("3"),
        time_in_force: "DAY",
        oca_group_identifier: "oca_group",
        account: "account",
        open_close: :O,
        origin: 0,
        order_ref: "order_ref",
        transmit: "transmit",
        parent_id: 1,
        block_order: true,
        sweep_to_fill: true,
        display_size: 0,
        trigger_method: 0,
        outside_rth: false,
        hidden: true
      }

      assert Order.new(params) |> Order.serialize(:first_batch) == [
               params.action,
               params.total_quantity,
               params.order_type,
               params.limit_price,
               params.aux_price,
               params.time_in_force,
               params.oca_group_identifier,
               params.account,
               params.open_close,
               params.origin,
               params.order_ref,
               params.transmit,
               params.parent_id,
               params.block_order,
               params.sweep_to_fill,
               params.display_size,
               params.trigger_method,
               params.outside_rth,
               params.hidden
             ]
    end

    test "serializes second batch of parameters for RequestCreateOrder" do
      params = %{
        discretionary_amount: Decimal.new("123"),
        good_after_time: "20240908 13:13:13",
        good_till_date: "20240908 13:13:13",
        fa_params: %{
          group_identifier: "fa_group",
          method: "fa_method",
          percentage: "fa_percentage"
        },
        model_code: "model_code",
        short_sale_params: %{
          short_sale_slot: 2,
          designated_location: "location",
          exempt_code: -1
        },
        oca_type: 1,
        rule_80a: "I",
        settling_firm: "settling_firm",
        all_or_none: true,
        min_quantity: 123,
        percent_offset: Decimal.new(".04"),
        auction_strategy: 0,
        starting_price: Decimal.new("123"),
        stock_reference_price: Decimal.new("789"),
        delta: Decimal.new(".1"),
        stock_range_lower: Decimal.new("69"),
        stock_range_upper: Decimal.new("99"),
        override_percentage_constraints: true,
        volatility_order_params: %{
          volatility: Decimal.new("0.2"),
          volatility_type: 1,
          delta_neutral_order_type: "LMT",
          delta_neutral_aux_price: Decimal.new("123"),
          delta_neutral_conid: 2,
          delta_neutral_settling_firm: "settling_firm",
          delta_neutral_clearing_account: "clearing_account",
          delta_neutral_clearing_intent: "clearing_intent",
          delta_neutral_open_close: "open_close",
          delta_neutral_short_sale: true,
          delta_neutral_short_sale_slot: 1,
          delta_neutral_designated_location: "designated_location"
        },
        continuous_update: 1,
        reference_price_type: 1,
        trail_stop_price: Decimal.new("12"),
        trailing_percent: Decimal.new(".13"),
        scale_order_params: %{
          init_level_size: 14,
          subs_level_size: 15,
          price_increment: 1,
          price_adjust_value: Decimal.new("16"),
          price_adjust_interval: 1,
          profit_offset: Decimal.new("17"),
          auto_reset: false,
          init_position: 5,
          init_fill_quantity: 2,
          random_percent: true,
          table: "table",
          active_start_time: "20240908 13:14:15",
          active_stop_time: "20240908 14:15:16"
        },
        hedge_order_params: %{
          hedge_type: "D",
          hedge_param: "beta=X"
        },
        opt_out_smart_routing: true,
        clearing_params: %{
          account: "clearing_account",
          settling_firm: "clearing_settling_firm",
          clearing_account: "clearing_account",
          clearing_intent: "IB"
        },
        not_held: true
      }

      assert Order.new(params) |> Order.serialize(:second_batch) == [
               nil,
               params.discretionary_amount,
               params.good_after_time,
               params.good_till_date,
               params.fa_params.group_identifier,
               params.fa_params.method,
               params.fa_params.percentage,
               params.model_code,
               params.short_sale_params.short_sale_slot,
               params.short_sale_params.designated_location,
               params.short_sale_params.exempt_code,
               params.oca_type,
               params.rule_80a,
               params.settling_firm,
               params.all_or_none,
               params.min_quantity,
               params.percent_offset,
               false,
               false,
               nil,
               params.auction_strategy,
               params.starting_price,
               params.stock_reference_price,
               params.delta,
               params.stock_range_lower,
               params.stock_range_upper,
               params.override_percentage_constraints,
               params.volatility_order_params.volatility,
               params.volatility_order_params.volatility_type,
               params.volatility_order_params.delta_neutral_order_type,
               params.volatility_order_params.delta_neutral_aux_price,
               params.volatility_order_params.delta_neutral_conid,
               params.volatility_order_params.delta_neutral_settling_firm,
               params.volatility_order_params.delta_neutral_clearing_account,
               params.volatility_order_params.delta_neutral_clearing_intent,
               params.volatility_order_params.delta_neutral_open_close,
               params.volatility_order_params.delta_neutral_short_sale,
               params.volatility_order_params.delta_neutral_short_sale_slot,
               params.volatility_order_params.delta_neutral_designated_location,
               params.continuous_update,
               params.reference_price_type,
               params.trail_stop_price,
               params.trailing_percent,
               params.scale_order_params.init_level_size,
               params.scale_order_params.subs_level_size,
               params.scale_order_params.price_increment,
               params.scale_order_params.price_adjust_value,
               params.scale_order_params.price_adjust_interval,
               params.scale_order_params.profit_offset,
               params.scale_order_params.auto_reset,
               params.scale_order_params.init_position,
               params.scale_order_params.init_fill_quantity,
               params.scale_order_params.random_percent,
               params.scale_order_params.table,
               params.scale_order_params.active_start_time,
               params.scale_order_params.active_stop_time,
               params.hedge_order_params.hedge_type,
               params.hedge_order_params.hedge_param,
               params.opt_out_smart_routing,
               params.clearing_params.clearing_account,
               params.clearing_params.clearing_intent,
               params.not_held
             ]
    end

    test "serializes third batch of parameters for RequestCreateOrder" do
      params = %{
        order_type: "PEG BENCH",
        algo_params: %{
          algo_strategy: "algo_strategy",
          algo_id: "algo_id",
          algo_params: [TagValue.new()]
        },
        what_if_info_and_commission: true,
        misc_options: [],
        solicited: true,
        randomize_size: true,
        randomize_price: true,
        peg_to_bench_params: %{
          reference_contract_id: 1,
          is_pegged_change_amount_decrease: true,
          pegged_change_amount: Decimal.new("1.0"),
          reference_change_amoung: Decimal.new("2.0"),
          reference_exchange_id: "reference_exchange_id"
        },
        order_conditions_params: %{
          conditions: [],
          conditions_cancel_order: true,
          conditions_ignore_rth: true
        },
        adjusted_order_type: "adjusted_order_type",
        trigger_price: :unset_double,
        limit_price_offset: :unset_double,
        adjusted_stop_price: :unset_double,
        adjusted_stop_limit_price: :unset_double,
        adjusted_trailing_amount: :unset_double,
        adjustable_trailing_unit: 2,
        ext_operator: "ext_operator",
        soft_dollar_tier_params: %{
          name: "name",
          value: Decimal.new("123"),
          display_name: "display_name"
        },
        cash_quantity: Decimal.new("234"),
        mifid2_decision_maker: "mifid2_decision_maker",
        mifid2_decision_algo: "mifid2_decision_algo",
        mifid2_execution_trader: "mifid2_decision_maker",
        mifid2_execution_algo: "mifid2_execution_algo",
        dont_use_autoprice_for_hedge: false,
        is_oms_container: true,
        discretionary_up_to_limit_price: true,
        use_price_management_algo: false,
        duration: :unset_integer,
        post_to_ats: :unset_integer,
        auto_cancel_parent: true,
        advanced_error_override: false,
        manual_order_time: "manual_order_time"
      }

      assert Order.new(params) |> Order.serialize(:third_batch) == [
               params.algo_params.algo_strategy,
               length(params.algo_params.algo_params),
               nil,
               nil,
               params.algo_params.algo_id,
               params.what_if_info_and_commission,
               "",
               params.solicited,
               params.randomize_size,
               params.randomize_price,
               params.peg_to_bench_params.reference_contract_id,
               params.peg_to_bench_params.is_pegged_change_amount_decrease,
               params.peg_to_bench_params.pegged_change_amount,
               params.peg_to_bench_params.reference_change_amoung,
               params.peg_to_bench_params.reference_exchange_id,
               0,
               params.adjusted_order_type,
               params.trigger_price,
               params.limit_price_offset,
               params.adjusted_stop_price,
               params.adjusted_stop_limit_price,
               params.adjusted_trailing_amount,
               params.adjustable_trailing_unit,
               params.ext_operator,
               params.soft_dollar_tier_params.name,
               params.soft_dollar_tier_params.value,
               params.cash_quantity,
               params.mifid2_decision_maker,
               params.mifid2_decision_algo,
               params.mifid2_execution_trader,
               params.mifid2_execution_algo,
               params.dont_use_autoprice_for_hedge,
               params.is_oms_container,
               params.discretionary_up_to_limit_price,
               params.use_price_management_algo,
               params.duration,
               params.post_to_ats,
               params.auto_cancel_parent,
               params.advanced_error_override,
               params.manual_order_time
             ]
    end

    test "serializes last batch of parameters for RequestCreateOrder if order_type is PEG BEST" do
      params = %{
        order_type: "PEG BEST",
        min_compete_size: 123,
        compete_against_best_offset: Decimal.new("99"),
        customer_account: "customer_account",
        professional_customer: "professional_customer",
        external_user_id: "external_user_id",
        manual_order_indicator: 99
      }

      assert Order.new(params) |> Order.serialize(:fourth_batch) == [
               params.min_compete_size,
               params.compete_against_best_offset,
               params.customer_account,
               params.professional_customer,
               params.external_user_id,
               params.manual_order_indicator
             ]
    end

    test "serializes last batch of parameters for RequestCreateOrder if order_type is PEG BEST and compete_against_best_offset == :infinity" do
      params = %{
        order_type: "PEG BEST",
        min_compete_size: 123,
        compete_against_best_offset: :infinity,
        mid_offset_at_whole: Decimal.new("123"),
        mid_offset_at_half: Decimal.new("234"),
        customer_account: "customer_account",
        professional_customer: "professional_customer",
        external_user_id: "external_user_id",
        manual_order_indicator: 99
      }

      assert Order.new(params) |> Order.serialize(:fourth_batch) == [
               params.min_compete_size,
               params.compete_against_best_offset,
               params.mid_offset_at_whole,
               params.mid_offset_at_half,
               params.customer_account,
               params.professional_customer,
               params.external_user_id,
               params.manual_order_indicator
             ]
    end

    test "serializes last batch of parameters for RequestCreateOrder if order_type is PEG MID" do
      params = %{
        order_type: "PEG MID",
        customer_account: "customer_account",
        professional_customer: "professional_customer",
        external_user_id: "external_user_id",
        manual_order_indicator: 99
      }

      assert Order.new(params) |> Order.serialize(:fourth_batch) == [
               params.customer_account,
               params.professional_customer,
               params.external_user_id,
               params.manual_order_indicator
             ]
    end
  end
end
