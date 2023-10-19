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
            volatility_order_params: nil,
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
            use_price_management_algo: nil

  # @times_in_force ~w(
  #  DAY GTC IOC GTD OPG FOK DTC
  # )

  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end
end
