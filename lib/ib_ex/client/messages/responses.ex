defmodule IbEx.Client.Messages.Responses do
  alias IbEx.Client.Messages
  alias Messages.Base
  alias IbEx.Client.Protocols.Traceable

  require Logger

  @ids_to_message_type %{
    "1" => Messages.MarketData.TickPrice,
    "2" => Messages.MarketData.TickSize,
    "3" => Messages.Orders.Status,
    "4" => Messages.ErrorInfo.Base,
    "5" => Messages.Orders.OpenOrder,
    "6" => Messages.AccountData.AccountDetail,
    "7" => "portfolio_value",
    "8" => Messages.AccountData.AccountUpdateTime,
    "9" => Messages.Ids.NextValidId,
    "10" => "contract_data",
    "11" => Messages.Executions.ExecutionData,
    "12" => Messages.MarketDepth.L2DataSingle,
    "13" => Messages.MarketDepth.L2DataMultiple,
    "14" => Messages.News.Bulletins,
    "15" => Messages.Misc.ManagedAccounts,
    "16" => "receive_fa",
    "17" => "historical_data",
    "18" => "bond_contract_data",
    "19" => "scanner_parameters",
    "20" => "scanner_data",
    "21" => "tick_option_computation",
    "45" => Messages.MarketData.TickGeneric,
    "46" => Messages.MarketData.TickString,
    "47" => "tick_efp",
    "49" => Messages.CurrentTime.Response,
    "50" => "real_time_bars",
    "51" => "fundamental_data",
    "52" => "contract_data_end",
    "53" => "open_order_end",
    "54" => Messages.AccountData.AccountDownloadEnd,
    "55" => Messages.Executions.ExecutionDataEnd,
    "56" => "deta_neutral_validation",
    "57" => "tick_snapshot_end",
    "58" => Messages.MarketData.MarketDataType,
    "59" => Messages.Executions.CommissionReport,
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
    "75" => Messages.MarketData.OptionChain,
    "76" => Messages.MarketData.OptionChainEnd,
    "77" => "soft_dollar_tiers",
    "78" => "family_codes",
    "79" => Messages.MatchingSymbols.SymbolSamples,
    "80" => Messages.MarketDepth.Exchanges,
    "81" => Messages.MarketData.TickRequestParams,
    "82" => "smart_components",
    "83" => Messages.News.ArticleData,
    "84" => Messages.MarketData.TickNews,
    "85" => Messages.News.Providers,
    "86" => Messages.News.HistoricalNews,
    "87" => Messages.News.HistoricalNewsEnd,
    "88" => "head_timestamp",
    "89" => "histogram_data",
    "90" => "historical_data_update",
    "91" => "reroute_mkt_data_req",
    "92" => "reroute_mkt_depth_req",
    "93" => "market_rule",
    "94" => Messages.Pnl.AllPositionsUpdate,
    "95" => Messages.Pnl.SinglePositionUpdate,
    "96" => "historical_ticks",
    "97" => "historical_ticks_bid_ask",
    "98" => Messages.HistoricalTicks.Last,
    "99" => Messages.TickByTickData.TickByTick,
    "100" => "order_bound",
    "101" => "completed_orders",
    "102" => "completed_orders_end",
    "103" => "replace_fa_end",
    "104" => "wsh_meta_data",
    "105" => "wsh_event_data",
    "106" => "historical_schedule",
    "107" => "user_info"
  }

  @spec parse(String.t(), atom(), boolean()) :: {:ok, any()} | {:error, :unexpected_error} | {:error, :not_implemented}
  def parse(str, :connecting, trace_messages) do
    {:ok, msg} =
      str
      |> Base.get_fields()
      |> Messages.InitConnection.Response.from_fields()

    if trace_messages do
      Logger.info(Traceable.to_s(msg))
    end

    {:ok, msg}
  end

  def parse(str, _, trace_messages) do
    with fields <- Base.get_fields(str),
         {:ok, msg_id} <- Base.message_id_from_fields(fields),
         {:ok, type} <- Map.fetch(@ids_to_message_type, msg_id),
         {:ok, type} <- validate_implemented(type),
         {:ok, msg} <- type.from_fields(Enum.slice(fields, 1..-1//1)) do
      if trace_messages do
        Logger.info(Traceable.to_s(msg))
      end

      {:ok, msg}
    else
      {:error, {:not_implemented, _type}} ->
        fields = Base.get_fields(str)
        Logger.warning("<-- #{inspect(fields, limit: :infinity)}")
        {:error, :not_implemented}

      err ->
        fields = Base.get_fields(str)
        Logger.warning("Frame: #{inspect(str, limit: :infinity)}")
        Logger.warning("Fields: #{inspect(fields, limit: :infinity)}")
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
