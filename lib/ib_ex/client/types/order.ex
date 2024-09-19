defmodule IbEx.Client.Types.Order do
  @moduledoc """
  Represents an Order.
  """

  alias IbEx.Client.Types.TagValueList

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
    MidOffsets,
    ComboLeg,
    SmartComboRoutingParams
  }

  import IbEx.Client.Utils, only: [list_to_union_type: 1]

  defstruct api_client_order_id: nil,
            api_client_id: nil,
            host_order_id: nil,
            action: nil,
            total_quantity: nil,
            order_type: nil,
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
            smart_combo_routing_params: [],
            discretionary_amount: 0,
            good_after_time: nil,
            good_till_date: nil,
            fa_params: nil,
            model_code: nil,
            short_sale_params: nil,
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
            volatility_order_params: nil,
            continuous_update: false,
            reference_price_type: nil,
            trail_stop_price: nil,
            trailing_percent: nil,
            scale_order_params: nil,
            hedge_order_params: nil,
            opt_out_smart_routing: false,
            clearing_params: nil,
            not_held: false,
            algo_params: nil,
            what_if_info_and_commission: false,
            misc_options: [],
            solicited: false,
            randomize_size: false,
            randomize_price: false,
            peg_to_bench_params: nil,
            order_conditions_params: [],
            adjusted_order_type: nil,
            trigger_price: :unset_double,
            limit_price_offset: :unset_double,
            adjusted_stop_price: :unset_double,
            adjusted_stop_limit_price: :unset_double,
            adjusted_trailing_amount: :unset_double,
            adjustable_trailing_unit: 0,
            ext_operator: nil,
            soft_dollar_tier_params: nil,
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
            customer_account: nil,
            professional_customer: false,
            external_user_id: nil,
            manual_order_indicator: :unset_integer

  @times_in_force ~w(
   DAY GTC IOC GTD OPG FOK DTC
  )a
  @type times_in_force :: unquote(list_to_union_type(@times_in_force))

  @type open_close :: :O | :C

  # 0 = Customer, 1 = Firm, 2 = unknown
  @type origin :: 0..2

  # 0=Default, 1=Double_Bid_Ask, 2=Last, 3=Double_Last, 4=Bid_Ask, 7=Last_or_Bid_Ask, 8=Mid-point
  @type trigger_method :: 0..8

  # 1 = CANCEL_WITH_BLOCK, 2 = REDUCE_WITH_BLOCK, 3 = REDUCE_NON_BLOCK
  @type oca_type :: 1..3

  # Individual = 'I', Agency = 'A', AgentOtherMember = 'W', IndividualPTIA = 'J', AgencyPTIA = 'U', AgentOtherMemberPTIA = 'M', IndividualPT = 'K', AgencyPT = 'Y', AgentOtherMemberPT = 'N'
  @rules_80a ~w(I A W J U M K Y N)a
  @type rules_80a :: unquote(list_to_union_type(@rules_80a))

  # 0 = AUCTION_UNSET, 1 = AUCTION_MATCH, 2 = AUCTION_IMPROVEMENT, 3 = AUCTION_TRANSPARENT
  @type auction_strategy :: 0..3

  # 1 = :average, 2 = :bid_or_ask
  @type reference_price_type :: 1..2
  # https://www.interactivebrokers.com/campus/ibkr-api-page/twsapi-ref/#order-ref
  @type t :: %__MODULE__{
          # ORDER IDENTIFIER 
          api_client_order_id: non_neg_integer(),
          api_client_id: non_neg_integer(),
          host_order_id: non_neg_integer(),

          # MAIN ORDER FIELDS 
          action: binary(),
          total_quantity: non_neg_integer(),
          order_type: binary(),
          limit_price: Decimal.t(),
          aux_price: Decimal.t(),

          # EXTENDED ORDER FIELDS
          time_in_force: times_in_force(),
          oca_group_identifier: binary(),
          account: binary(),
          open_close: open_close(),
          origin: origin(),
          order_ref: binary(),
          transmit: boolean(),
          parent_id: non_neg_integer(),
          block_order: boolean(),
          sweep_to_fill: boolean(),
          display_size: non_neg_integer(),
          trigger_method: trigger_method(),
          outside_rth: boolean(),
          hidden: boolean(),
          combo_legs: list(ComboLeg.t()),
          smart_combo_routing_params: SmartComboRoutingParams.t(),
          discretionary_amount: Decimal.t(),
          good_after_time: binary(),
          good_till_date: binary(),
          fa_params: FinancialAdvisorParams.t(),
          model_code: binary(),
          short_sale_params: ShortSaleParams.t(),
          oca_type: oca_type(),
          rule_80a: rules_80a(),
          settling_firm: binary(),
          all_or_none: boolean(),
          min_quantity: integer(),
          percent_offset: Decimal.t(),
          auction_strategy: auction_strategy(),
          starting_price: Decimal.t(),
          stock_reference_price: Decimal.t(),
          delta: Decimal.t(),
          stock_range_lower: Decimal.t(),
          stock_range_upper: Decimal.t(),
          override_percentage_constraints: boolean(),
          volatility_order_params: VolatilityOrderParams.t(),
          continuous_update: boolean() | nil,
          reference_price_type: reference_price_type(),
          trail_stop_price: Decimal.t(),
          trailing_percent: Decimal.t(),
          scale_order_params: ScaleOrderParams.t(),
          hedge_order_params: HedgeOrderParams.t(),
          opt_out_smart_routing: boolean(),
          clearing_params: ClearingInfoParams.t(),
          not_held: boolean(),
          algo_params: AlgoOrderParams.t(),
          what_if_info_and_commission: boolean(),
          misc_options: TagValueList.t(),
          solicited: boolean(),
          randomize_size: boolean(),
          randomize_price: boolean(),
          peg_to_bench_params: PegToBenchmarkOrderParams.t(),
          order_conditions_params: OrderConditionsParams.t(),
          adjusted_order_type: binary(),
          trigger_price: Decimal.t() | float(),
          limit_price_offset: Decimal.t() | float(),
          adjusted_stop_price: Decimal.t() | float(),
          adjusted_stop_limit_price: Decimal.t() | float(),
          adjusted_trailing_amount: Decimal.t() | float(),
          adjustable_trailing_unit: integer(),
          ext_operator: binary(),
          soft_dollar_tier_params: SoftDollarTierParams.t(),
          cash_quantity: Decimal.t(),
          mifid2_decision_maker: binary(),
          mifid2_decision_algo: binary(),
          mifid2_execution_trader: binary(),
          mifid2_execution_algo: binary(),
          dont_use_autoprice_for_hedge: boolean(),
          is_oms_container: boolean(),
          discretionary_up_to_limit_price: boolean(),
          use_price_management_algo: boolean() | nil,
          duration: integer(),
          post_to_ats: integer(),
          auto_cancel_parent: binary(),
          advanced_error_override: binary(),
          manual_order_time: binary(),
          min_trade_quantity: non_neg_integer(),
          min_compete_size: non_neg_integer(),
          compete_against_best_offset: Decimal.t() | :infinity,
          mid_offset_at_whole: Decimal.t(),
          mid_offset_at_half: Decimal.t(),
          customer_account: binary(),
          professional_customer: boolean(),
          external_user_id: binary(),
          manual_order_indicator: non_neg_integer()
        }

  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    attrs =
      attrs
      |> assign_params(:fa_params, FinancialAdvisorParams)
      |> assign_params(:short_sale_params, ShortSaleParams)
      |> assign_params(:volatility_order_params, VolatilityOrderParams)
      |> assign_params(:scale_order_params, ScaleOrderParams)
      |> assign_params(:hedge_order_params, HedgeOrderParams)
      |> assign_params(:clearing_params, ClearingInfoParams)
      |> assign_params(:algo_params, AlgoOrderParams)
      |> assign_params(:peg_to_bench_params, PegToBenchmarkOrderParams)
      |> assign_params(:order_conditions_params, OrderConditionsParams)
      |> assign_params(:soft_dollar_tier_params, SoftDollarTierParams)
      |> assign_params(:smart_combo_routing_params, SmartComboRoutingParams)

    struct(__MODULE__, attrs)
  end

  def assign_params(attrs, key, module) do
    Map.put(attrs, key, module.new(Map.get(attrs, key, %{})))
  end

  @spec serialize(__MODULE__.t(), :first_batch | :second_batch | :third_batch | :fourth_batch) :: list() | :invalid_args
  def serialize(%__MODULE__{} = order, :first_batch) do
    [
      # beginning of order related fields
      order.action,
      order.total_quantity,
      order.order_type,
      order.limit_price,
      order.aux_price,

      # extended order fields 
      order.time_in_force,
      order.oca_group_identifier,
      order.account,
      order.open_close,
      order.origin,
      order.order_ref,
      order.transmit,
      order.parent_id,
      order.block_order,
      order.sweep_to_fill,
      order.display_size,
      order.trigger_method,
      order.outside_rth,
      order.hidden
    ]
  end

  def serialize(%__MODULE__{} = order, :second_batch) do
    [
      nil,
      order.discretionary_amount,
      order.good_after_time,
      order.good_till_date
    ] ++
      FinancialAdvisorParams.serialize(order.fa_params) ++
      [
        order.model_code
      ] ++
      ShortSaleParams.serialize(order.short_sale_params) ++
      [
        order.oca_type,
        order.rule_80a,
        order.settling_firm,
        order.all_or_none,
        order.min_quantity,
        order.percent_offset,
        false,
        false,
        nil,
        order.auction_strategy,
        order.starting_price,
        order.stock_reference_price,
        order.delta,
        order.stock_range_lower,
        order.stock_range_upper,
        order.override_percentage_constraints
      ] ++
      VolatilityOrderParams.serialize(order.volatility_order_params) ++
      [
        order.continuous_update,
        order.reference_price_type,
        order.trail_stop_price,
        order.trailing_percent
      ] ++
      ScaleOrderParams.serialize(order.scale_order_params) ++
      HedgeOrderParams.serialize(order.hedge_order_params) ++
      [
        order.opt_out_smart_routing
      ] ++
      ClearingInfoParams.serialize(order.clearing_params) ++
      [
        order.not_held
      ]
  end

  def serialize(%__MODULE__{} = order, :third_batch) do
    is_pegbench_order? = order.order_type == "PEG BENCH"

    AlgoOrderParams.serialize(order.algo_params) ++
      [
        order.what_if_info_and_commission,
        TagValueList.serialize_to_string(order.misc_options),
        order.solicited,
        order.randomize_size,
        order.randomize_price
      ] ++
      PegToBenchmarkOrderParams.serialize(order.peg_to_bench_params, is_pegbench_order?) ++
      OrderConditionsParams.serialize(order.order_conditions_params) ++
      [
        order.adjusted_order_type,
        order.trigger_price,
        order.limit_price_offset,
        order.adjusted_stop_price,
        order.adjusted_stop_limit_price,
        order.adjusted_trailing_amount,
        order.adjustable_trailing_unit,
        order.ext_operator
      ] ++
      SoftDollarTierParams.serialize(order.soft_dollar_tier_params) ++
      [
        order.cash_quantity,
        order.mifid2_decision_maker,
        order.mifid2_decision_algo,
        order.mifid2_execution_trader,
        order.mifid2_execution_algo,
        order.dont_use_autoprice_for_hedge,
        order.is_oms_container,
        order.discretionary_up_to_limit_price,
        order.use_price_management_algo,
        order.duration,
        order.post_to_ats,
        order.auto_cancel_parent,
        order.advanced_error_override,
        order.manual_order_time
      ]
  end

  def serialize(%__MODULE__{} = order, :fourth_batch) do
    MidOffsets.serialize(order) ++
      [
        order.customer_account,
        order.professional_customer,
        order.external_user_id,
        order.manual_order_indicator
      ]
  end

  def serialize(%__MODULE__{}, _), do: :invalid_args

  @spec maybe_serialize_combo_legs(__MODULE__.t(), boolean()) :: list()
  def maybe_serialize_combo_legs(%__MODULE__{} = order, true) do
    [length(order.combo_legs)] ++
      (Enum.reduce(order.combo_legs, [], fn %ComboLeg{} = leg, acc ->
         [leg.price | acc]
       end)
       |> Enum.reverse()
       |> List.flatten())
  end

  def maybe_serialize_combo_legs(_, _), do: []

  @spec maybe_serialize_smart_combo_routing_params(__MODULE__.t(), boolean()) :: list()
  def maybe_serialize_smart_combo_routing_params(%__MODULE__{} = order, true) do
    SmartComboRoutingParams.serialize(order.smart_combo_routing_params)
  end

  def maybe_serialize_smart_combo_routing_params(_, _), do: []

  @spec maybe_serialize_min_trade_quantity(__MODULE__.t(), boolean()) :: list()
  def maybe_serialize_min_trade_quantity(%__MODULE__{} = order, true) do
    [order.min_trade_quantity]
  end

  def maybe_serialize_min_trade_quantity(_, _), do: []
end
