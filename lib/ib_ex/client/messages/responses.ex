defmodule IbEx.Client.Messages.Responses do
  alias IbEx.Client.Messages
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types

  require Logger

  @protobuf_offset 200

  @decoders %{
    1 => Proto.TickPrice,
    2 => Proto.TickSize,
    3 => Proto.OrderStatus,
    # 4 => ErrorMessage handled separately (Error/Info dispatch)
    5 => Proto.OpenOrder,
    6 => Proto.AccountValue,
    7 => Proto.PortfolioValue,
    8 => Proto.AccountUpdateTime,
    9 => Proto.NextValidId,
    10 => Proto.ContractData,
    11 => Proto.ExecutionDetails,
    12 => Proto.MarketDepth,
    13 => Proto.MarketDepthL2,
    14 => Proto.NewsBulletin,
    15 => Proto.ManagedAccounts,
    16 => Proto.ReceiveFA,
    17 => Proto.HistoricalData,
    18 => Proto.ContractData,
    19 => Proto.ScannerParameters,
    20 => Proto.ScannerData,
    21 => Proto.TickOptionComputation,
    45 => Proto.TickGeneric,
    46 => Proto.TickString,
    # 47 => tick_efp: Exchange for Physicals financing rate data (basis points, implied futures, hold days).
    #       Niche instrument type with no proto definition or protobuf handler in canonical TWS API.
    49 => Proto.CurrentTime,
    50 => Proto.RealTimeBarTick,
    51 => Proto.FundamentalsData,
    52 => Proto.ContractDataEnd,
    53 => Proto.OpenOrdersEnd,
    54 => Proto.AccountDataEnd,
    55 => Proto.ExecutionDetailsEnd,
    56 => Proto.DeltaNeutralContract,
    57 => Proto.TickSnapshotEnd,
    58 => Proto.MarketDataType,
    59 => Proto.CommissionAndFeesReport,
    61 => Proto.Position,
    62 => Proto.PositionEnd,
    63 => Proto.AccountSummary,
    64 => Proto.AccountSummaryEnd,
    65 => Proto.VerifyMessageApi,
    66 => Proto.VerifyCompleted,
    67 => Proto.DisplayGroupList,
    68 => Proto.DisplayGroupUpdated,
    # 69 => verify_and_auth_message_api: Part of a restricted authentication challenge-response flow
    # 70 => verify_and_auth_completed:   marked "not generally available" in TWS API docs.
    #       No proto definition or protobuf handler in canonical TWS API. Standard auth uses StartApi.
    71 => Proto.PositionMulti,
    72 => Proto.PositionMultiEnd,
    73 => Proto.AccountUpdateMulti,
    74 => Proto.AccountUpdateMultiEnd,
    75 => Proto.SecDefOptParameter,
    76 => Proto.SecDefOptParameterEnd,
    77 => Proto.SoftDollarTiers,
    78 => Proto.FamilyCodes,
    79 => Proto.SymbolSamples,
    80 => Proto.MarketDepthExchanges,
    81 => Proto.TickReqParams,
    82 => Proto.SmartComponents,
    83 => Proto.NewsArticle,
    84 => Proto.TickNews,
    85 => Proto.NewsProviders,
    86 => Proto.HistoricalNews,
    87 => Proto.HistoricalNewsEnd,
    88 => Proto.HeadTimestamp,
    89 => Proto.HistogramData,
    90 => Proto.HistoricalDataUpdate,
    91 => Proto.RerouteMarketDataRequest,
    92 => Proto.RerouteMarketDepthRequest,
    93 => Proto.MarketRule,
    94 => Proto.PnL,
    95 => Proto.PnLSingle,
    96 => Proto.HistoricalTicks,
    97 => Proto.HistoricalTicksBidAsk,
    98 => Proto.HistoricalTicksLast,
    99 => Proto.TickByTickData,
    100 => Proto.OrderBound,
    101 => Proto.CompletedOrder,
    102 => Proto.CompletedOrdersEnd,
    103 => Proto.ReplaceFAEnd,
    104 => Proto.WshMetaData,
    105 => Proto.WshEventData,
    106 => Proto.HistoricalSchedule,
    107 => Proto.UserInfo,
    108 => Proto.HistoricalDataEnd,
    109 => Proto.CurrentTimeInMillis,
    110 => Proto.ConfigResponse
  }

  @spec parse(binary(), atom(), boolean()) :: {:ok, any()} | {:error, :unexpected_error}
  def parse(str, :connecting, _trace_messages) do
    fields =
      str
      |> String.split("\x00")
      |> Enum.slice(0..-2//1)

    Messages.InitConnection.Response.from_fields(fields)
  end

  def parse(<<raw_msg_id::big-integer-size(32), payload::binary>>, _, _trace_messages) do
    msg_id = raw_msg_id - @protobuf_offset

    case decode(msg_id, payload) do
      {:ok, _msg} = ok ->
        ok

      {:error, reason} ->
        Logger.warning(
          "Protobuf frame: msg_id=#{msg_id} raw=#{raw_msg_id} payload=#{inspect(payload, limit: :infinity)}"
        )

        Logger.error("Unexpected Error: #{inspect(reason)}")
        {:error, :unexpected_error}
    end
  end

  # ErrorMessage (msg_id=4): dispatch to Error or Info based on id == -1
  defp decode(4, payload) do
    proto = Proto.ErrorMessage.decode(payload)

    fields = %{
      id: proto.id,
      code: proto.error_code,
      message: proto.error_msg
    }

    if proto.id == -1 do
      {:ok, struct(Types.Info, fields)}
    else
      {:ok, struct(Types.Error, fields)}
    end
  rescue
    err ->
      Logger.warning("Error decoding ErrorMessage protobuf: #{inspect(err)}")
      {:error, :decode_error}
  end

  # Generic decoder for all other message types
  defp decode(msg_id, payload) when is_map_key(@decoders, msg_id) do
    module = Map.fetch!(@decoders, msg_id)
    {:ok, module.decode(payload)}
  rescue
    err ->
      Logger.warning("Error decoding msg_id=#{msg_id} protobuf: #{inspect(err)}")
      {:error, :decode_error}
  end

  # Unknown message ID
  defp decode(_msg_id, _payload) do
    {:error, :unknown_message_id}
  end
end
