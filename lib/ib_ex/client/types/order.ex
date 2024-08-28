defmodule IbEx.Client.Types.Order do
  @moduledoc """
  Represents an Order.  
  """

  alias IbEx.Client.Types.Order.VolatilityOrderParams
  alias IbEx.Client.Messages.Orders.Decoder.FinancialAdvisorParams
  alias IbEx.Client.Types.Order.{ShortSaleParams, FinancialAdvisorParams}
  import IbEx.Client.Utils, only: [list_to_type: 1]

  # ORDER IDENTIFIER 
  defstruct api_client_order_id: nil,
            api_client_id: nil,
            host_order_id: nil,
            # contract: nil,

            # MAIN ORDER FIELDS
            action: nil,
            total_quantity: nil,
            order_type: nil,
            limit_price: nil,
            aux_price: nil,

            # EXTENDED ORDER FIELDS 
            time_in_force: nil,
            active_start_time: nil,
            active_stop_time: nil,
            oca_group_identifier: nil,
            oca_type: 0,
            order_ref: nil,
            transmit: true,
            parent_id: 0,
            block_order: false,
            sweep_to_fill: false,
            display_size: 0,
            # 0=Default, 1=Double_Bid_Ask, 2=Last, 3=Double_Last, 4=Bid_Ask, 7=Last_or_Bid_Ask, 8=Mid-point
            trigger_method: 0,
            outside_rth: nil,
            hidden: nil,
            good_after_time: nil,
            good_till_date: nil,
            # Individual = 'I', Agency = 'A', AgentOtherMember = 'W', IndividualPTIA = 'J', AgencyPTIA = 'U', AgentOtherMemberPTIA = 'M', IndividualPT = 'K', AgencyPT = 'Y', AgentOtherMemberPT = 'N'
            rule_80a: nil,
            all_or_none: false,
            min_quantity: nil,
            percent_offset: nil,
            override_percentage_constraints: false,
            trail_stop_price: nil,
            trailing_percent: nil,

            # FINANCIAL ADVISORS ONLY
            account: nil,
            open_close: nil,
            origin: nil,
            discretionary_amount: nil,
            skip_shares_allocation: nil,
            fa_params: nil,
            model_code: nil,
            settling_firm: nil,
            short_sale_params: nil,
            auction_strategy: nil,
            box_order_params: nil,
            peg_to_stock_or_volume_params: nil,
            etrade_only: nil,
            firm_quote_only: nil,
            nbbo_price_cap: nil,
            volatility_params: nil,
            trail_params: nil,
            basis_points: nil,
            basis_points_type: nil,
            combo_legs: nil,
            smart_combo_routing_params: nil,
            scale_order_params: nil,
            hedge_params: nil,
            opt_out_smart_routing: nil,
            clearing_params: nil,
            not_held: nil,
            delta_neutral: nil,
            algo_params: nil,
            solicited: nil,
            what_if_info_and_commission: nil,
            vol_randomized_flags: nil,
            peg_to_bench_params: nil,
            conditions: nil,
            adjusted_order_params: nil,
            soft_dollar_tier: nil,
            cash_quantity: nil,
            dont_use_autoprice_for_hedge: nil,
            is_oms_container: nil,
            discretionary_up_to_limit_price: nil,
            use_price_management_algo: nil,
            starting_price: nil,
            stock_range_lower: nil,
            stock_range_upper: nil,
            stock_reference_price: nil,
            delta: nil

  # CLEARING INFO

  @times_in_force ~w(
   DAY GTC IOC GTD OPG FOK DTC
  )a

  @type times_in_force :: unquote(list_to_type(@times_in_force))

  # @rules_80a ~w(I A W J U M K Y N)a

  # https://www.interactivebrokers.com/campus/ibkr-api-page/twsapi-ref/#order-ref
  @type t :: %__MODULE__{
          # ORDER IDENTIFIER 
          api_client_order_id: non_neg_integer(),
          api_client_id: non_neg_integer(),
          host_order_id: non_neg_integer(),
          # TODO: do we need Contract here?
          # contract: Contract.t(),

          # MAIN ORDER FIELDS 
          action: binary(),
          total_quantity: Decimal.t(),
          order_type: binary(),
          limit_price: float(),
          # TODO: check type ???
          aux_price: float(),

          # EXTENDED ORDER FIELDS
          time_in_force: binary(),
          oca_group_identifier: binary(),
          oca_type: 1..3,
          order_ref: binary(),
          transmit: boolean(),
          parent_id: non_neg_integer(),
          block_order: boolean(),
          sweep_to_fill: boolean(),
          display_size: non_neg_integer(),
          trigger_method: non_neg_integer(),
          outside_rth: boolean(),
          hidden: boolean(),
          good_after_time: binary(),
          good_till_date: binary(),
          rule_80a: binary(),
          all_or_none: boolean(),
          min_quantity: non_neg_integer(),
          percent_offset: float(),
          override_percentage_constraints: boolean(),
          trail_stop_price: float(),
          trailing_percent: float(),

          # FINANCIAL ADVISORS ONLY
          fa_params: FinancialAdvisorParams.t()
        }

  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    attrs =
      attrs
      |> Map.put(:fa_params, FinancialAdvisorParams.new(Map.get(attrs, :fa_params, %{})))
      |> Map.put(:short_sale_params, ShortSaleParams.new(Map.get(attrs, :short_sale_params, %{})))
      |> Map.put(:volatility_params, VolatilityOrderParams.new(Map.get(attrs, :volatility_params, %{})))

    struct(__MODULE__, attrs)
  end

  def serialize(%__MODULE__{} = order) do
    [
      # beginning of order related fields
      order.action,
      # total quantity here is a decimal or float for fractional positions
      order.total_quantity,
      order.order_type,
      # handle empty
      order.limit_price,
      # handle empty
      order.aux_price

      # extended order fields 
      #   order.time_in_force,
      #   order.oca_group_identifier,
      #   order.account,
      #   order.open_close,
      #   order.origin,
      #   order.order_ref,
      #   order.transmit,
      #   order.parent_id,
      #   order.block_order,
      #   order.sweep_to_fill,
      #   order.display_size,
      #   order.trigger_method,
      #   order.outside_rth,
      #   order.hidden
      # ] ++
      #   [
      #     # BAG order params
      #   ] ++
      #   [
      #     nil,
      #     order.discretionary_amount,
      #     order.good_after_time,
      #     order.good_till_date
      #   ] ++
      #   FinancialAdvisorParams.serialize(order.fa_params) ++
      #   [order.model_code] ++
      #   ShortSaleParams.serialize(order.short_sale_params) ++
      #   [
      #     order.oca_type,
      #     order.rule_80a,
      #     order.settling_firm,
      #     order.all_or_none,
      #     order.min_quantity,
      #     order.percent_offset,
      #     false,
      #     false,
      #     nil,
      #     order.auction_strategy,
      #     order.starting_price,
      #     order.stock_reference_price,
      #     order.delta,
      #     order.stock_range_lower,
      #     order.stock_range_upper,
      #     order.override_percentage_constraints,
      #     order.volatility_params.volatility,
      #     order.volatility_params.volatility_type,
      #     order.volatility_params.delta_neutral_order_type,
      #     order.volatility_params.delta_neutral_aux_price
    ]

    # TODO: add delta_neutral params
  end
end
