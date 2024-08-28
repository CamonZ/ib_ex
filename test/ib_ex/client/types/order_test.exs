defmodule IbEx.Client.Types.OrderTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.VolatilityOrderParams
  alias IbEx.Client.Types.Order.{FinancialAdvisorParams, ShortSaleParams}
  alias IbEx.Client.Types.Order

  describe "new/1" do
    test "creates an Order with valid attributes" do
      attrs = %{
        api_client_order_id: 1,
        api_client_id: 2,
        host_order_id: 3,
        action: "BUY",
        total_quantity: Decimal.new("10"),
        order_type: "IBALGO"
      }

      assert Order.new(attrs) == %Order{
               api_client_order_id: 1,
               api_client_id: 2,
               host_order_id: 3,
               action: "BUY",
               total_quantity: Decimal.new("10"),
               order_type: "IBALGO",
               limit_price: nil,
               aux_price: nil,
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
               trigger_method: 0,
               outside_rth: nil,
               hidden: nil,
               good_after_time: nil,
               good_till_date: nil,
               rule_80a: nil,
               all_or_none: false,
               min_quantity: nil,
               percent_offset: nil,
               override_percentage_constraints: false,
               trail_stop_price: nil,
               trailing_percent: nil,
               account: nil,
               open_close: nil,
               origin: nil,
               discretionary_amount: nil,
               skip_shares_allocation: nil,
               fa_params: FinancialAdvisorParams.new(),
               model_code: nil,
               settling_firm: nil,
               short_sale_params: ShortSaleParams.new(),
               auction_strategy: nil,
               box_order_params: nil,
               peg_to_stock_or_volume_params: nil,
               etrade_only: nil,
               firm_quote_only: nil,
               nbbo_price_cap: nil,
               volatility_params: VolatilityOrderParams.new(),
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
             }
    end

    test "creates an Order with valid Financial Advisor attributes" do
      attrs = %{
        api_client_order_id: 1,
        api_client_id: 2,
        host_order_id: 3,
        action: "BUY",
        total_quantity: Decimal.new("10"),
        order_type: "IBALGO",
        fa_params: %{
          group_identifier: "fa_group",
          method: "fa_method",
          percentage: "fa_percentage",
          profile: "fa_profile"
        }
      }

      assert Order.new(attrs) == %Order{
               api_client_order_id: 1,
               api_client_id: 2,
               host_order_id: 3,
               action: "BUY",
               total_quantity: Decimal.new("10"),
               order_type: "IBALGO",
               fa_params: %FinancialAdvisorParams{
                 group_identifier: "fa_group",
                 method: "fa_method",
                 percentage: "fa_percentage",
                 profile: "fa_profile"
               },
               short_sale_params: ShortSaleParams.new(),
               volatility_params: VolatilityOrderParams.new()
             }
    end

    test "creates an Order with valid Short Sale attributes" do
      attrs = %{
        api_client_order_id: 1,
        api_client_id: 2,
        host_order_id: 3,
        action: "BUY",
        total_quantity: Decimal.new("10"),
        order_type: "IBALGO",
        short_sale_params: %{
          slot: "short_sale_slot",
          location: "short_sale_location",
          code: "short_sale_code"
        }
      }

      assert Order.new(attrs) == %Order{
               api_client_order_id: 1,
               api_client_id: 2,
               host_order_id: 3,
               action: "BUY",
               total_quantity: Decimal.new("10"),
               order_type: "IBALGO",
               fa_params: FinancialAdvisorParams.new(),
               short_sale_params: %ShortSaleParams{
                 slot: "short_sale_slot",
                 location: "short_sale_location",
                 code: "short_sale_code"
               },
               volatility_params: VolatilityOrderParams.new()
             }
    end

    test "creates an Order with valid Volatility attributes" do
      attrs = %{
        api_client_order_id: 1,
        api_client_id: 2,
        host_order_id: 3,
        action: "BUY",
        total_quantity: Decimal.new("10"),
        order_type: "IBALGO",
        volatility_params: %{
          volatility: Decimal.new("0.2"),
          volatility_type: 1,
          delta_neutral_order_type: "LMT",
          delta_neutral_aux_price: Decimal.new("123")
        }
      }

      assert Order.new(attrs) == %Order{
               api_client_order_id: 1,
               api_client_id: 2,
               host_order_id: 3,
               action: "BUY",
               total_quantity: Decimal.new("10"),
               order_type: "IBALGO",
               fa_params: FinancialAdvisorParams.new(),
               short_sale_params: ShortSaleParams.new(),
               volatility_params: %VolatilityOrderParams{
                 volatility: Decimal.new("0.2"),
                 volatility_type: 1,
                 delta_neutral_order_type: "LMT",
                 delta_neutral_aux_price: Decimal.new("123")
               }
             }
    end
  end

  describe "serialize/1" do
    test "serializes an Order" do
      attrs = %{
        api_client_order_id: 1,
        api_client_id: 2,
        host_order_id: 3,
        action: "BUY",
        total_quantity: Decimal.new("10"),
        order_type: "IBALGO",
        fa_params: %{
          group_identifier: "fa_group",
          method: "fa_method",
          percentage: "fa_percentage",
          profile: "fa_profile"
        },
        short_sale_params: %{
          slot: "short_sale_slot",
          location: "short_sale_location",
          code: "short_sale_code"
        },
        volatility_params: %{
          volatility: Decimal.new("0.2"),
          volatility_type: 1,
          delta_neutral_order_type: "LMT",
          delta_neutral_aux_price: Decimal.new("123")
        }
      }

      order = Order.new(attrs)
      serialized = Order.serialize(order)

      # MAIN ORDER FIELDS
      assert serialized |> Enum.slice(0, 3) == [
               "BUY",
               Decimal.new("10"),
               "IBALGO"
             ]

      # FINANCIAL ADVISOR FIELDS
      assert serialized |> Enum.slice(23, 4) == [
               "fa_group",
               "fa_profile",
               "fa_method",
               "fa_percentage"
             ]

      # SHORT SALE FIELDS
      assert serialized |> Enum.slice(28, 3) == [
               "short_sale_slot",
               "short_sale_location",
               "short_sale_code"
             ]

      # VOLATILITY FIELDS
      assert serialized |> Enum.slice(47, 4) == [
               Decimal.new("0.2"),
               1,
               "LMT",
               Decimal.new("123")
             ]
    end
  end
end
