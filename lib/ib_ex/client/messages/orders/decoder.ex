defmodule IbEx.Client.Messages.Orders.Decoder do
  @moduledoc """
        // read order id
        eOrderDecoder.readTrailParams();

        eOrderDecoder.readBasisPoints();

        eOrderDecoder.readComboLegs();

        eOrderDecoder.readSmartComboRoutingParams();

        eOrderDecoder.readScaleOrderParams();

        eOrderDecoder.readHedgeParams();

        eOrderDecoder.readOptOutSmartRouting();
        eOrderDecoder.readClearingParams();
        eOrderDecoder.readNotHeld();
        eOrderDecoder.readDeltaNeutral();
        eOrderDecoder.readAlgoParams();
        eOrderDecoder.readSolicited();
        eOrderDecoder.readWhatIfInfoAndCommission();
        eOrderDecoder.readVolRandomizeFlags();
        eOrderDecoder.readPegToBenchParams();
        eOrderDecoder.readConditions();
        eOrderDecoder.readAdjustedOrderParams();
        eOrderDecoder.readSoftDollarTier();
        eOrderDecoder.readCashQty();
        eOrderDecoder.readDontUseAutoPriceForHedge();
        eOrderDecoder.readIsOmsContainer();
        eOrderDecoder.readDiscretionaryUpToLimitPrice();
        eOrderDecoder.readUsePriceMgmtAlgo();
  """

  @first_batch [
    :action,
    :total_quantity,
    :order_type,
    :limit_price,
    :aux_price,
    :time_in_force,
    :oca_group_identifier,
    :account,
    :open_close,
    :origin,
    :order_ref,
    :api_client_id,
    :host_order_id,
    :outside_rth,
    :hidden,
    :discretionary_amount,
    :good_after_time,
    :shares_allocation
  ]

  @second_batch [
    :model_code,
    :good_till_date,
    :rule_80a,
    :percent_offset,
    :settling_firm
  ]

  @third_batch [
    :display_size,
    :block_order,
    :sweep_to_fill,
    :all_or_none,
    :min_quantity,
    :oca_type,
    :etrade_only,
    :firm_quote_only,
    :nbbo_price_cap,
    :parent_id,
    :trigger_method
  ]

  # @order_field_names [
  #  :basis_points,
  #  :basis_points_type,
  #  :combo_legs,
  #  :smart_combo_routing_params,
  #  :scale_order_params,
  #  :hedge_params,
  #  :opt_out_smart_routing,
  #  :clearing_params,
  #  :not_held,
  #  :delta_neutral,
  #  :algo_params,
  #  :solicited,
  #  :what_if_info_and_commission,
  #  :vol_randomized_flags,
  #  :peg_to_bench_params,
  #  :conditions,
  #  :adjusted_order_params,
  #  :soft_dollar_tier,
  #  :cash_quantity,
  #  :dont_use_autoprice_for_hedge,
  #  :is_oms_container,
  #  :discretionary_up_to_limit_price,
  #  :use_price_management_algo
  # ]

  alias IbEx.Client.Types.Contract

  alias IbEx.Client.Messages.Orders.Decoder.FinancialAdvisorParams
  alias IbEx.Client.Messages.Orders.Decoder.ShortSaleParams
  alias IbEx.Client.Messages.Orders.Decoder.BoxOrderParams
  alias IbEx.Client.Messages.Orders.Decoder.PegToStockOrVolumeOrderParams

  def parse(fields) do
    [api_client_order_id | rest] = fields

    %{}
    |> Map.put(:api_client_order_id, api_client_order_id)
    |> Map.put(:unprocessed, rest)
    |> parse_contract_data()
    |> batch_parse_params(@first_batch)
    |> parse_custom_params(FinancialAdvisorParams, :fa_params)
    |> batch_parse_params(@second_batch)
    |> parse_custom_params(ShortSaleParams, :short_sale_params)
    |> batch_parse_params([:auction_strategy])
    |> parse_custom_params(BoxOrderParams, :box_order_params)
    |> parse_custom_params(PegToStockOrVolumeOrderParams, :peg_to_stock_or_volume_params)
    |> batch_parse_params(@third_batch)

    # |> parse_custom_params(VolatilityOrderParamsDecoder, :volatility_order_params, open_order: true)
    # |> parse_custom_params(TrailParamsDecoder, :trail_params)
  end

  defp parse_contract_data(%{unprocessed: fields} = msg) do
    {contract_data, rest} = Enum.split(fields, 11)
    contract = Contract.deserialize(contract_data)
    Map.merge(msg, %{contract: contract, unprocessed: rest})
  end

  defp batch_parse_params(%{unprocessed: fields} = msg, keys) do
    {order_data, rest} = Enum.split(fields, length(keys))

    order_fields = Enum.zip(keys, order_data)
    data = Map.merge(msg, Enum.into(order_fields, %{}))

    Map.put(data, :unprocessed, rest)
  end

  defp parse_custom_params(%{unprocessed: fields} = msg, module, key, _opts \\ []) do
    {params, rest} = module.parse(fields)

    msg
    |> Map.put(:unprocessed, rest)
    |> Map.put(key, params)
  end
end
