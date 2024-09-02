defmodule IbEx.Client.Types.Order do
  @moduledoc """
  Represents an Order.  
  """

  alias IbEx.Client.Types.Order.ComboLeg

  alias IbEx.Client.Types.Order.{
    ShortSaleParams,
    FinancialAdvisorParams,
    VolatilityOrderParams,
    TrailParams,
    HedgeOrderParams,
    ScaleOrderParams,
    ClearingInfoParams,
    AlgoOrderParams,
    MiscOptionsParams,
    PegToBenchmarkOrderParams,
    OrderConditionsParams,
    SoftDollarTierParams,
    MidOffsets
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
            origin: nil,
            order_ref: nil,
            transmit: true,
            parent_id: 0,
            block_order: false,
            sweep_to_fill: false,
            display_size: 0,
            trigger_method: 0,
            outside_rth: nil,
            hidden: nil,
            combo_legs: [],
            discretionary_amount: nil,
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
            trail_order_params: nil,
            scale_order_params: nil,
            hedge_order_params: nil,
            opt_out_smart_routing: nil,
            clearing_params: nil,
            not_held: false,
            algo_params: nil,
            what_if_info_and_commission: false,
            misc_options_params: nil,
            solicited: false,
            randomize_size: false,
            randomize_price: false,
            peg_to_bench_params: nil,
            order_conditions_params: [],
            adjusted_order_type: nil,
            trigger_price: nil,
            limit_price_offset: nil,
            adjusted_stop_price: nil,
            adjusted_stop_limit_price: nil,
            adjusted_trailing_amount: nil,
            adjustable_trailing_unit: nil,
            ext_operator: nil,
            soft_dollar_tier_params: nil,
            cash_quantity: nil,
            mifid2_decision_maker: nil,
            mifid2_decision_algo: nil,
            mifid2_execution_trader: nil,
            mifid2_execution_algo: nil,
            dont_use_autoprice_for_hedge: false,
            is_oms_container: false,
            discretionary_up_to_limit_price: false,
            use_price_management_algo: nil,
            duration: nil,
            post_to_ats: nil,
            auto_cancel_parent: nil,
            advanced_error_override: nil,
            manual_order_time: nil,
            min_trade_quantity: nil,
            min_compete_size: nil,
            compete_against_best_offset: nil,
            mid_offset_at_whole: nil,
            mid_offset_at_half: nil

  @times_in_force ~w(
   DAY GTC IOC GTD OPG FOK DTC
  )a

  # Individual = 'I', Agency = 'A', AgentOtherMember = 'W', IndividualPTIA = 'J', AgencyPTIA = 'U', AgentOtherMemberPTIA = 'M', IndividualPT = 'K', AgencyPT = 'Y', AgentOtherMemberPT = 'N'
  @rules_80a ~w(I A W J U M K Y N)a

  @type times_in_force :: unquote(list_to_union_type(@times_in_force))

  # 0 = Client, 1 = Firm, 2 = unknown
  @type origin :: 0..2

  # 0=Default, 1=Double_Bid_Ask, 2=Last, 3=Double_Last, 4=Bid_Ask, 7=Last_or_Bid_Ask, 8=Mid-point
  @type trigger_method :: 0..8

  # 1 = CANCEL_WITH_BLOCK, 2 = REDUCE_WITH_BLOCK, 3 = REDUCE_NON_BLOCK
  @type oca_type :: 1..3
  @type rules_80a :: unquote(list_to_union_type(@rules_80a))

  # 0 = AUCTION_UNSET, 1 = AUCTION_MATCH, 2 = AUCTION_IMPROVEMENT, 3 = AUCTION_TRANSPARENT
  @type auction_strategy :: 0..3
  @type open_close :: :O | :C

  # https://www.interactivebrokers.com/campus/ibkr-api-page/twsapi-ref/#order-ref
  @type t :: %__MODULE__{
          # ORDER IDENTIFIER 
          api_client_order_id: non_neg_integer(),
          api_client_id: non_neg_integer(),
          host_order_id: non_neg_integer(),

          # MAIN ORDER FIELDS 
          action: binary(),
          total_quantity: Decimal.t(),
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
          min_quantity: non_neg_integer(),
          percent_offset: Decimal.t(),
          auction_strategy: auction_strategy(),
          starting_price: Decimal.t(),
          stock_reference_price: Decimal.t(),
          delta: Decimal.t(),
          stock_range_lower: Decimal.t(),
          stock_range_upper: Decimal.t(),
          override_percentage_constraints: boolean(),
          volatility_order_params: VolatilityOrderParams.t(),
          trail_order_params: TrailParams.t(),
          scale_order_params: ScaleOrderParams.t(),
          hedge_order_params: HedgeOrderParams.t(),
          opt_out_smart_routing: boolean(),
          clearing_params: ClearingInfoParams.t(),
          not_held: boolean(),
          algo_params: AlgoOrderParams.t(),
          what_if_info_and_commission: boolean(),
          misc_options_params: MiscOptionsParams.t(),
          solicited: boolean(),
          randomize_size: boolean(),
          randomize_price: boolean(),
          peg_to_bench_params: PegToBenchmarkOrderParams.t(),
          order_conditions_params: OrderConditionsParams.t(),
          adjusted_order_type: binary(),
          trigger_price: Decimal.t(),
          limit_price_offset: Decimal.t(),
          adjusted_stop_price: Decimal.t(),
          adjusted_stop_limit_price: Decimal.t(),
          adjusted_trailing_amount: Decimal.t(),
          adjustable_trailing_unit: non_neg_integer(),
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
          duration: non_neg_integer(),
          post_to_ats: non_neg_integer(),
          auto_cancel_parent: binary(),
          advanced_error_override: binary(),
          manual_order_time: non_neg_integer(),
          min_trade_quantity: non_neg_integer(),
          min_compete_size: non_neg_integer(),
          compete_against_best_offset: Decimal.t() | :infinity,
          mid_offset_at_whole: Decimal.t(),
          mid_offset_at_half: Decimal.t()
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
      |> assign_params(:trail_order_params, TrailParams)
      |> assign_params(:scale_order_params, ScaleOrderParams)
      |> assign_params(:hedge_order_params, HedgeOrderParams)
      |> assign_params(:clearing_params, ClearingInfoParams)
      |> assign_params(:algo_params, AlgoOrderParams)
      |> assign_params(:misc_options_params, MiscOptionsParams)
      |> assign_params(:peg_to_bench_params, PegToBenchmarkOrderParams)
      |> assign_params(:order_conditions_params, OrderConditionsParams)
      |> assign_params(:soft_dollar_tier_params, SoftDollarTierParams)

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
      # total quantity here is a decimal or float for fractional positions
      order.total_quantity,
      order.order_type,
      # handle empty
      order.limit_price,
      # handle empty
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
        # send deprecated shares_allocation field
        nil,
        order.discretionary_amount,
        order.good_after_time,
        order.good_till_date
      ] ++
      FinancialAdvisorParams.serialize(order.fa_params) ++
      [order.model_code] ++
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
      TrailParams.serialize(order.trail_order_params) ++
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
    AlgoOrderParams.serialize(order.algo_params) ++
      [
        order.what_if_info_and_commission,
        MiscOptionsParams.serialize(order.misc_options_params),
        order.solicited,
        order.randomize_size,
        order.randomize_price
      ] ++
      PegToBenchmarkOrderParams.serialize(order.peg_to_bench_params) ++
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
    MidOffsets.serialize(order)
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

  def maybe_serialize_combo_legs(_,_), do: []
    
  @spec maybe_serialize_min_trade_quantity(__MODULE__.t(), boolean()) :: list()
    def maybe_serialize_min_trade_quantity(%__MODULE__{} = order, true) do
      [order.min_trade_quantity]
    end

    def maybe_serialize_min_trade_quantity(_, _), do: []
end
