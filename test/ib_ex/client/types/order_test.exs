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
    MiscOptionsParams,
    PegToBenchmarkOrderParams,
    OrderConditionsParams,
    SoftDollarTierParams,
    MidOffsets,
    ComboLeg,
    SmartComboRoutingParams
  }

  alias IbEx.Client.Types.Order

  describe "new/1" do
    @tag :order
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
               continuous_update: nil,
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
               misc_options_params: MiscOptionsParams.new(),
               solicited: false,
               randomize_size: false,
               randomize_price: false,
               peg_to_bench_params: nil,
               peg_to_bench_params: PegToBenchmarkOrderParams.new(),
               order_conditions_params: OrderConditionsParams.new(),
               adjusted_order_type: nil,
               trigger_price: Order.unset_double(),
               limit_price_offset: Order.unset_double(),
               adjusted_stop_price: Order.unset_double(),
               adjusted_stop_limit_price: Order.unset_double(),
               adjusted_trailing_amount: Order.unset_double(),
               adjustable_trailing_unit: 0,
               ext_operator: nil,
               soft_dollar_tier_params: SoftDollarTierParams.new(),
               cash_quantity: Order.unset_double(),
               mifid2_decision_maker: nil,
               mifid2_decision_algo: nil,
               mifid2_execution_trader: nil,
               mifid2_execution_algo: nil,
               dont_use_autoprice_for_hedge: false,
               is_oms_container: false,
               discretionary_up_to_limit_price: false,
               use_price_management_algo: nil,
               duration: Order.unset_integer(),
               post_to_ats: Order.unset_integer(),
               auto_cancel_parent: false,
               advanced_error_override: nil,
               manual_order_time: nil,
               min_trade_quantity: nil,
               min_compete_size: nil,
               compete_against_best_offset: nil,
               mid_offset_at_whole: nil,
               mid_offset_at_half: nil
             }
    end

    #   test "creates an Order with valid Financial Advisor attributes" do
    #     attrs = %{
    #       api_client_order_id: 1,
    #       api_client_id: 2,
    #       host_order_id: 3,
    #       action: "BUY",
    #       total_quantity: Decimal.new("10"),
    #       order_type: "IBALGO",
    #       fa_params: %{
    #         group_identifier: "fa_group",
    #         method: "fa_method",
    #         percentage: "fa_percentage",
    #         profile: "fa_profile"
    #       }
    #     }
    #
    #     assert Order.new(attrs) == %Order{
    #              api_client_order_id: 1,
    #              api_client_id: 2,
    #              host_order_id: 3,
    #              action: "BUY",
    #              total_quantity: Decimal.new("10"),
    #              order_type: "IBALGO",
    #              fa_params: %FinancialAdvisorParams{
    #                group_identifier: "fa_group",
    #                method: "fa_method",
    #                percentage: "fa_percentage",
    #                profile: "fa_profile"
    #              },
    #              short_sale_params: ShortSaleParams.new(),
    #              volatility_params: VolatilityOrderParams.new()
    #            }
    #   end
    #
    #   test "creates an Order with valid Short Sale attributes" do
    #     attrs = %{
    #       api_client_order_id: 1,
    #       api_client_id: 2,
    #       host_order_id: 3,
    #       action: "BUY",
    #       total_quantity: Decimal.new("10"),
    #       order_type: "IBALGO",
    #       short_sale_params: %{
    #         slot: "short_sale_slot",
    #         location: "short_sale_location",
    #         code: "short_sale_code"
    #       }
    #     }
    #
    #     assert Order.new(attrs) == %Order{
    #              api_client_order_id: 1,
    #              api_client_id: 2,
    #              host_order_id: 3,
    #              action: "BUY",
    #              total_quantity: Decimal.new("10"),
    #              order_type: "IBALGO",
    #              fa_params: FinancialAdvisorParams.new(),
    #              short_sale_params: %ShortSaleParams{
    #                slot: "short_sale_slot",
    #                location: "short_sale_location",
    #                code: "short_sale_code"
    #              },
    #              volatility_params: VolatilityOrderParams.new()
    #            }
    #   end
    #
    #   test "creates an Order with valid Volatility attributes" do
    #     attrs = %{
    #       api_client_order_id: 1,
    #       api_client_id: 2,
    #       host_order_id: 3,
    #       action: "BUY",
    #       total_quantity: Decimal.new("10"),
    #       order_type: "IBALGO",
    #       volatility_params: %{
    #         volatility: Decimal.new("0.2"),
    #         volatility_type: 1,
    #         delta_neutral_order_type: "LMT",
    #         delta_neutral_aux_price: Decimal.new("123")
    #       }
    #     }
    #
    #     assert Order.new(attrs) == %Order{
    #              api_client_order_id: 1,
    #              api_client_id: 2,
    #              host_order_id: 3,
    #              action: "BUY",
    #              total_quantity: Decimal.new("10"),
    #              order_type: "IBALGO",
    #              fa_params: FinancialAdvisorParams.new(),
    #              short_sale_params: ShortSaleParams.new(),
    #              volatility_params: %VolatilityOrderParams{
    #                volatility: Decimal.new("0.2"),
    #                volatility_type: 1,
    #                delta_neutral_order_type: "LMT",
    #                delta_neutral_aux_price: Decimal.new("123")
    #              }
    #            }
    #   end
    # end
    #
    # describe "serialize/1" do
    #   test "serializes an Order" do
    #     attrs = %{
    #       api_client_order_id: 1,
    #       api_client_id: 2,
    #       host_order_id: 3,
    #       action: "BUY",
    #       total_quantity: Decimal.new("10"),
    #       order_type: "IBALGO",
    #       fa_params: %{
    #         group_identifier: "fa_group",
    #         method: "fa_method",
    #         percentage: "fa_percentage",
    #         profile: "fa_profile"
    #       },
    #       short_sale_params: %{
    #         slot: "short_sale_slot",
    #         location: "short_sale_location",
    #         code: "short_sale_code"
    #       },
    #       volatility_params: %{
    #         volatility: Decimal.new("0.2"),
    #         volatility_type: 1,
    #         delta_neutral_order_type: "LMT",
    #         delta_neutral_aux_price: Decimal.new("123")
    #       }
    #     }
    #
    #     order = Order.new(attrs)
    #     serialized = Order.serialize(order)
    #
    #     # MAIN ORDER FIELDS
    #     assert serialized |> Enum.slice(0, 3) == [
    #              "BUY",
    #              Decimal.new("10"),
    #              "IBALGO"
    #            ]
    #
    #     # FINANCIAL ADVISOR FIELDS
    #     assert serialized |> Enum.slice(23, 4) == [
    #              "fa_group",
    #              "fa_profile",
    #              "fa_method",
    #              "fa_percentage"
    #            ]
    #
    #     # SHORT SALE FIELDS
    #     assert serialized |> Enum.slice(28, 3) == [
    #              "short_sale_slot",
    #              "short_sale_location",
    #              "short_sale_code"
    #            ]
    #
    #     # VOLATILITY FIELDS
    #     assert serialized |> Enum.slice(47, 4) == [
    #              Decimal.new("0.2"),
    #              1,
    #              "LMT",
    #              Decimal.new("123")
    #            ]
    #   end
  end
end
