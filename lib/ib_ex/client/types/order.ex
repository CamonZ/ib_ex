defmodule IbEx.Client.Types.Order do
  defstruct api_client_order_id: nil,
            api_client_id: nil,
            contract: nil,
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
            transmit: nil,
            host_order_id: nil,
            outside_rth: nil,
            hidden: nil,
            discretionary_amount: nil,
            good_after_time: nil,
            skip_shares_allocation: nil,
            fa_params: nil,
            model_code: nil,
            good_till_date: nil,
            rule_80a: nil,
            percent_offset: nil,
            settling_firm: nil,
            short_sale_params: nil,
            auction_strategy: nil,
            box_order_params: nil,
            peg_to_stock_or_volume_params: nil,
            display_size: nil,
            block_order: nil,
            sweep_to_fill: nil,
            all_or_none: nil,
            min_quantity: nil,
            oca_type: nil,
            etrade_only: nil,
            firm_quote_only: nil,
            nbbo_price_cap: nil,
            parent_id: nil,
            trigger_method: nil,
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
            stock_range_low: nil,
            stock_range_upper: nil,
            override_percentage_concerns: nil,
            stock_reference_price: nil,
            delta: nil

  # @times_in_force ~w(
  #  DAY GTC IOC GTD OPG FOK DTC
  # )

  alias IbEx.Client.Types.Order.ShortSaleParams

  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end

  def serializable_fields(%__MODULE__{} = order) do
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
    ] ++
      [
        # BAG order params
      ] ++
      [
        "",
        order.discretionary_amount,
        order.good_after_time,
        order.good_till_date,
        order.fa_params.group_identifier,
        order.fa_params.method,
        order.fa_params.percentage,
        order.model_code
      ] ++
      ShortSaleParams.serializable_fields(order.short_sale_params) ++
      [
        order.oca_type,
        order.rule_80a,
        order.settling_firm,
        order.min_quantity,
        order.percent_offset,
        false,
        false,
        # insert here unset double
        order.auction_strategy,
        order.starting_price,
        order.stock_reference_price,
        order.delta,
        order.stock_range_low,
        order.stock_range_upper,
        order.override_percentage_concerns,
        order.volatility_params.volatility,
        order.volatility_params.volatility_type,
        order.volatility_params.delta_neutral_order_type,
        order.volatility_params.delta_neutral_aux_price
      ]
  end
end
