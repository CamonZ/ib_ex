defmodule IbEx.Client.Messages.Responses do
  alias IbEx.Client.Messages
  alias Messages.Base

  require Logger

  @ids_to_message_type %{
    "1" => "tick_price",
    "2" => "tick_size",
    "3" => Messages.Orders.Status,
    "4" => Messages.ErrorInfo.Base,
    "5" => Messages.Orders.OpenOrder,
    "6" => Messages.AccountData.AccountDetail,
    "7" => "portfolio_value",
    "8" => Messages.AccountData.AccountDetail,
    "9" => Messages.Ids.NextValidId,
    "10" => "contract_data",
    "11" => "execution_data",
    "12" => "market_depth",
    "13" => "market_depth_level_2",
    "14" => "news_bulletins",
    "15" => Messages.Misc.ManagedAccounts,
    "16" => "receive_fa",
    "17" => "historical_data",
    "18" => "bond_contract_data",
    "19" => "scanner_parameters",
    "20" => "scanner_data",
    "21" => "tick_option_computation",
    "45" => "tick_generic",
    "46" => "tick_string",
    "47" => "tick_efp",
    "49" => Messages.CurrentTime.Response,
    "50" => "real_time_bars",
    "51" => "fundamental_data",
    "52" => "contract_data_end",
    "53" => "open_order_end",
    "54" => Messages.AccountData.AccountDownloadEnd,
    "55" => "execution_data_end",
    "56" => "deta_neutral_validation",
    "57" => "tick_snapshot_end",
    "58" => "market_data_type",
    "59" => Messages.Misc.CommissionReport,
    "61" => "position_data",
    "62" => "position_end",
    "63" => "account_summary",
    "64" => "account_summary_end",
    "65" => "verify_message_api",
    "66" => "verify_completed",
    "67" => "display_group_list",
    "68" => "display_group_updated",
    "69" => "verify_and_auth_message_api",
    "70" => "verify_and_auth_completed",
    "71" => "position_multi",
    "72" => "position_multi_end",
    "73" => "account_update_multi",
    "74" => "account_update_multi_end",
    "75" => "security_definition_option_parameter",
    "76" => "security_definition_option_parameter_end",
    "77" => "soft_dollar_tiers",
    "78" => "family_codes",
    "79" => Messages.MatchingSymbols.SymbolSamples,
    "80" => "market_depth_exchanges",
    "81" => "tick_req_params",
    "82" => "smart_components",
    "83" => "news_article",
    "84" => "tick_news",
    "85" => "news_providers",
    "86" => "historical_news",
    "87" => "historical_news_end",
    "88" => "head_timestamp",
    "89" => "histogram_data",
    "90" => "historical_data_update",
    "91" => "reroute_mkt_data_req",
    "92" => "reroute_mkt_depth_req",
    "93" => "market_rule",
    "94" => IbEx.Client.Messages.Pnl.AllPositionsUpdate,
    "95" => IbEx.Client.Messages.Pnl.SinglePositionUpdate,
    "96" => "historical_ticks",
    "97" => "historical_ticks_bid_ask",
    "98" => Messages.HistoricalTicks.Last,
    "99" => "tick_by_tick",
    "100" => "order_bound",
    "101" => "completed_orders",
    "102" => "completed_orders_end",
    "103" => "replace_fa_end",
    "104" => "whs_meta_data",
    "105" => "whs_event_data",
    "106" => "historical_schedule",
    "107" => "user_info"
  }

  def parse(str, :connecting) do
    str
    |> Base.get_fields()
    |> Messages.InitConnection.Response.from_fields()
  end

  def parse(str, _) do
    with fields <- Base.get_fields(str),
         {:ok, msg_id} <- Base.message_id_from_fields(fields),
         {:ok, type} <- Map.fetch(@ids_to_message_type, msg_id),
         {:ok, type} <- validate_implemented(type),
         {:ok, msg} <- type.from_fields(Enum.slice(fields, 1..-1)) do
      Logger.info("#{inspect(msg)}")

      {:ok, msg}
    else
      {:error, {:not_implemented, _type}} ->
        fields = Base.get_fields(str)

        Logger.warning("<-- #{inspect(fields, limit: :infinity)}")

      err ->
        Logger.warning("Frame: #{inspect(str, printable_limit: :infinity)}")
        Logger.error("Unexpected Error: #{inspect(err)}")
        {:error, :unexpected_error}
    end
  end

  defp validate_implemented(type) when is_binary(type) do
    {:error, {:not_implemented, type}}
  end

  defp validate_implemented(type) when is_atom(type) do
    {:ok, type}
  end
end
