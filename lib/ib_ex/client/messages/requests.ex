defmodule IbEx.Client.Messages.Requests do
  alias IbEx.Client.Messages

  @message_ids %{
    "market_data" => 1,
    "cancel_market_data" => 2,
    "place_order" => 3,
    "cancel_order" => 4,
    "open_orders" => 5,
    Messages.AccountData.Request => 6,
    "executions" => 7,
    Messages.Ids.Request => 8,
    "contract_data" => 9,
    "market_depth" => 10,
    "cancel_market_depth" => 11,
    Messages.NewsBulletins.Request => 12,
    "cancel_news_bulletinsa" => 13,
    "set_server_log_level" => 14,
    "auto_open_orders" => 15,
    "all_open_orders" => 16,
    "managed_accounts" => 17,
    "financial_advisors" => 18,
    "replace_financial_advisors" => 19,
    "historical_data" => 20,
    "exercise_option" => 21,
    "scanner_subscription" => 22,
    "cancel_scanner_subscription" => 23,
    "scanner_parameters" => 24,
    "cancel_historical_data" => 25,
    Messages.CurrentTime.Request => 49,
    "real_time_bars" => 50,
    "cancel_real_time_bars" => 51,
    "fundamental_data" => 52,
    "cancel_fundamental_data" => 53,
    "calculated_implied_volatility" => 54,
    "calculated_option_price" => 55,
    "cancel_calculated_implied_volatility" => 56,
    "cancel_calculated_option_price" => 57,
    "global_cancel" => 58,
    "market_data_type" => 59,
    "positions" => 61,
    "account_summary" => 62,
    "cancel_account_summary" => 63,
    "cancel_positions" => 64,
    "verify_request" => 65,
    "verify_message" => 66,
    "query_display_groups" => 67,
    "subscribe_to_group_events" => 68,
    "update_display_group" => 69,
    "unsubscribe_from_group_events" => 70,
    Messages.StartApi.Request => 71,
    "verify_and_auth_request" => 72,
    "verify_and_auth_message" => 73,
    "positions_multi" => 74,
    "cancel_positions_multi" => 75,
    "account_updates_multi" => 76,
    "cancel_account_updates_multi" => 77,
    "sec_def_opt_params" => 78,
    "soft_dollar_tiers" => 79,
    "family_codes" => 80,
    Messages.MatchingSymbols.Request => 81,
    "market_depth_exchanges" => 82,
    "smart_components" => 83,
    "news_article" => 84,
    "news_providers" => 85,
    "historical_news" => 86,
    "head_timestamp" => 87,
    "histogram_data" => 88,
    "cancel_histogram_data" => 89,
    "cancel_head_timestamp" => 90,
    "market_rule" => 91,
    "profit_and_loss" => 92,
    "cancel_profit_and_loss" => 93,
    "profit_and_loss_single" => 94,
    "cancel_profit_and_loss_single" => 95,
    Messages.HistoricalTicks.Request => 96,
    "tick_by_tick_data" => 97,
    "cancel_tick_by_tick_data" => 98,
    "completed_orders" => 99,
    "wsh_meta_data" => 100,
    "cancel_wsh_meta_data" => 101,
    "wsh_event_data" => 102,
    "cancel_wsh_event_data" => 103,
    "user_info" => 104
  }

  @spec message_id_for(atom()) :: {:ok, non_neg_integer()} | :error
  def message_id_for(atom) do
    Map.fetch(@message_ids, atom)
  end
end
