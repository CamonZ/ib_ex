defmodule IbEx.Client.Messages.Requests do
  alias IbEx.Client.Proto.Protobuf, as: Proto

  @message_ids %{
    Proto.MarketDataRequest => 1,
    Proto.CancelMarketData => 2,
    Proto.PlaceOrderRequest => 3,
    Proto.CancelOrderRequest => 4,
    Proto.OpenOrdersRequest => 5,
    Proto.AccountDataRequest => 6,
    Proto.ExecutionRequest => 7,
    Proto.IdsRequest => 8,
    Proto.ContractDataRequest => 9,
    Proto.MarketDepthRequest => 10,
    Proto.CancelMarketDepth => 11,
    Proto.NewsBulletinsRequest => 12,
    Proto.CancelNewsBulletins => 13,
    Proto.SetServerLogLevelRequest => 14,
    Proto.AutoOpenOrdersRequest => 15,
    Proto.AllOpenOrdersRequest => 16,
    Proto.ManagedAccountsRequest => 17,
    Proto.FARequest => 18,
    Proto.FAReplace => 19,
    Proto.HistoricalDataRequest => 20,
    Proto.ExerciseOptionsRequest => 21,
    Proto.ScannerSubscriptionRequest => 22,
    Proto.CancelScannerSubscription => 23,
    Proto.ScannerParametersRequest => 24,
    Proto.CancelHistoricalData => 25,
    Proto.CurrentTimeRequest => 49,
    Proto.RealTimeBarsRequest => 50,
    Proto.CancelRealTimeBars => 51,
    Proto.FundamentalsDataRequest => 52,
    Proto.CancelFundamentalsData => 53,
    Proto.CalculateImpliedVolatilityRequest => 54,
    Proto.CalculateOptionPriceRequest => 55,
    Proto.CancelCalculateImpliedVolatility => 56,
    Proto.CancelCalculateOptionPrice => 57,
    Proto.GlobalCancelRequest => 58,
    Proto.MarketDataTypeRequest => 59,
    Proto.PositionsRequest => 61,
    Proto.AccountSummaryRequest => 62,
    Proto.CancelAccountSummary => 63,
    Proto.CancelPositions => 64,
    Proto.VerifyRequest => 65,
    Proto.VerifyMessageRequest => 66,
    Proto.QueryDisplayGroupsRequest => 67,
    Proto.SubscribeToGroupEventsRequest => 68,
    Proto.UpdateDisplayGroupRequest => 69,
    Proto.UnsubscribeFromGroupEventsRequest => 70,
    Proto.StartApiRequest => 71,
    # 72 => verify_and_auth_request: Part of a restricted authentication challenge-response flow
    # 73 => verify_and_auth_message:  marked "not generally available" in TWS API docs.
    #       No proto definition, legacy-only in canonical TWS API. Standard auth uses StartApi.
    Proto.PositionsMultiRequest => 74,
    Proto.CancelPositionsMulti => 75,
    Proto.AccountUpdatesMultiRequest => 76,
    Proto.CancelAccountUpdatesMulti => 77,
    Proto.SecDefOptParamsRequest => 78,
    Proto.SoftDollarTiersRequest => 79,
    Proto.FamilyCodesRequest => 80,
    Proto.MatchingSymbolsRequest => 81,
    Proto.MarketDepthExchangesRequest => 82,
    Proto.SmartComponentsRequest => 83,
    Proto.NewsArticleRequest => 84,
    Proto.NewsProvidersRequest => 85,
    Proto.HistoricalNewsRequest => 86,
    Proto.HeadTimestampRequest => 87,
    Proto.HistogramDataRequest => 88,
    Proto.CancelHistogramData => 89,
    Proto.CancelHeadTimestamp => 90,
    Proto.MarketRuleRequest => 91,
    Proto.PnLRequest => 92,
    Proto.CancelPnL => 93,
    Proto.PnLSingleRequest => 94,
    Proto.CancelPnLSingle => 95,
    Proto.HistoricalTicksRequest => 96,
    Proto.TickByTickRequest => 97,
    Proto.CancelTickByTick => 98,
    Proto.CompletedOrdersRequest => 99,
    Proto.WshMetaDataRequest => 100,
    Proto.CancelWshMetaData => 101,
    Proto.WshEventDataRequest => 102,
    Proto.CancelWshEventData => 103,
    Proto.UserInfoRequest => 104,
    Proto.CurrentTimeInMillisRequest => 105,
    Proto.CancelContractData => 106,
    Proto.CancelHistoricalTicks => 107,
    Proto.ConfigRequest => 108
  }

  @protobuf_offset 200

  @spec message_id_for(atom()) :: {:ok, non_neg_integer()} | :error
  def message_id_for(atom) do
    Map.fetch(@message_ids, atom)
  end

  @spec encode_request(struct()) :: {:ok, binary()} | :error
  def encode_request(%module{} = request) do
    with {:ok, msg_id} <- message_id_for(module) do
      wire_id = msg_id + @protobuf_offset
      payload = Protobuf.encode(request)

      {:ok, <<wire_id::big-integer-size(32), payload::binary>>}
    end
  end
end

defimpl IbEx.Client.Protocols.Subscribable, for: IbEx.Client.Proto.Protobuf.MatchingSymbolsRequest do
  alias IbEx.Client.Subscriptions

  def subscribe(msg, pid, table_ref) do
    request_id = Subscriptions.subscribe_by_request_id(table_ref, pid)
    {:ok, %{msg | req_id: request_id}}
  end

  def lookup(_, _), do: {:error, :lookup_not_necessary}
end
