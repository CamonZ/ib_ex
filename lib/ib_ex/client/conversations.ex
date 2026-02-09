defmodule IbEx.Client.Conversations do
  @moduledoc """
  Declarative registry of TWS conversation shapes.

  Maps each request proto module to its conversation metadata:
  type, correlation method, expected response types, end marker,
  and cancel request module.

  Provides compile-time derived indexes for efficient lookup.

  ## Conversation Types

  * `:request_response` -- single request, single response
  * `:bounded_stream` -- single request, multiple responses terminated by an end marker
  * `:stream` -- long-lived subscription producing continuous responses, cancelled explicitly
  * `:command` -- fire-and-forget request with no expected response

  ## Correlation Methods

  * `:req_id` -- response carries a `req_id` field matching the request
  * `:order_id` -- response carries an order ID field (e.g. PlaceOrder lifecycle)
  * `:global` -- response carries no `req_id`; ETS key is `{:global, request_module}`
  """

  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Subscriptions

  @conversations %{
    # -----------------------------------------------------------------------
    # Single request/response types (correlation: :req_id)
    # -----------------------------------------------------------------------
    Proto.HeadTimestampRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.HeadTimestamp]
    },
    Proto.HistogramDataRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.HistogramData]
    },
    Proto.FundamentalsDataRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.FundamentalsData]
    },
    Proto.NewsArticleRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.NewsArticle]
    },
    Proto.SoftDollarTiersRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.SoftDollarTiers]
    },
    Proto.SmartComponentsRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.SmartComponents]
    },
    Proto.UserInfoRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.UserInfo]
    },
    Proto.ConfigRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.ConfigResponse]
    },
    Proto.MatchingSymbolsRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.SymbolSamples]
    },

    # Single request/response types (correlation: :global -- no req_id)
    Proto.CurrentTimeRequest => %{
      type: :request_response,
      correlation: :global,
      responses: [Proto.CurrentTime]
    },
    Proto.CurrentTimeInMillisRequest => %{
      type: :request_response,
      correlation: :global,
      responses: [Proto.CurrentTimeInMillis]
    },
    Proto.ScannerParametersRequest => %{
      type: :request_response,
      correlation: :global,
      responses: [Proto.ScannerParameters]
    },
    Proto.NewsProvidersRequest => %{
      type: :request_response,
      correlation: :global,
      responses: [Proto.NewsProviders]
    },
    Proto.FamilyCodesRequest => %{
      type: :request_response,
      correlation: :global,
      responses: [Proto.FamilyCodes]
    },
    Proto.MarketDepthExchangesRequest => %{
      type: :request_response,
      correlation: :global,
      responses: [Proto.MarketDepthExchanges]
    },
    Proto.MarketRuleRequest => %{
      type: :request_response,
      correlation: :global,
      responses: [Proto.MarketRule]
    },

    # -----------------------------------------------------------------------
    # Bounded stream types (correlation: :req_id, with end markers)
    # -----------------------------------------------------------------------
    Proto.ContractDataRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.ContractData],
      end_marker: Proto.ContractDataEnd,
      cancel_request: Proto.CancelContractData
    },
    Proto.ExecutionRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.ExecutionDetails],
      end_marker: Proto.ExecutionDetailsEnd
    },
    Proto.HistoricalDataRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.HistoricalData, Proto.HistoricalDataUpdate, Proto.HistoricalSchedule],
      end_marker: Proto.HistoricalDataEnd,
      cancel_request: Proto.CancelHistoricalData
    },
    Proto.ScannerSubscriptionRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.ScannerData],
      cancel_request: Proto.CancelScannerSubscription
    },
    Proto.AccountSummaryRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.AccountSummary],
      end_marker: Proto.AccountSummaryEnd,
      cancel_request: Proto.CancelAccountSummary
    },
    Proto.PositionsMultiRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.PositionMulti],
      end_marker: Proto.PositionMultiEnd,
      cancel_request: Proto.CancelPositionsMulti
    },
    Proto.AccountUpdatesMultiRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.AccountUpdateMulti],
      end_marker: Proto.AccountUpdateMultiEnd,
      cancel_request: Proto.CancelAccountUpdatesMulti
    },
    Proto.SecDefOptParamsRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.SecDefOptParameter],
      end_marker: Proto.SecDefOptParameterEnd
    },
    Proto.HistoricalNewsRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.HistoricalNews],
      end_marker: Proto.HistoricalNewsEnd
    },
    Proto.HistoricalTicksRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.HistoricalTicks, Proto.HistoricalTicksBidAsk, Proto.HistoricalTicksLast],
      cancel_request: Proto.CancelHistoricalTicks
    },
    Proto.FAReplace => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [],
      end_marker: Proto.ReplaceFAEnd
    },

    # Bounded stream types (correlation: :global -- no req_id)
    Proto.OpenOrdersRequest => %{
      type: :bounded_stream,
      correlation: :global,
      responses: [Proto.OpenOrder],
      end_marker: Proto.OpenOrdersEnd
    },
    Proto.AllOpenOrdersRequest => %{
      type: :bounded_stream,
      correlation: :global,
      responses: [Proto.OpenOrder],
      end_marker: Proto.OpenOrdersEnd
    },
    Proto.AccountDataRequest => %{
      type: :bounded_stream,
      correlation: :global,
      responses: [Proto.AccountValue, Proto.PortfolioValue, Proto.AccountUpdateTime],
      end_marker: Proto.AccountDataEnd
    },
    Proto.PositionsRequest => %{
      type: :bounded_stream,
      correlation: :global,
      responses: [Proto.Position],
      end_marker: Proto.PositionEnd,
      cancel_request: Proto.CancelPositions
    },
    Proto.CompletedOrdersRequest => %{
      type: :bounded_stream,
      correlation: :global,
      responses: [Proto.CompletedOrder],
      end_marker: Proto.CompletedOrdersEnd
    },

    # -----------------------------------------------------------------------
    # Continuous stream types (correlation: :req_id)
    # -----------------------------------------------------------------------
    Proto.MarketDataRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [
        Proto.TickPrice,
        Proto.TickSize,
        Proto.TickGeneric,
        Proto.TickString,
        Proto.TickOptionComputation,
        Proto.TickReqParams,
        Proto.TickSnapshotEnd,
        Proto.TickNews,
        Proto.RerouteMarketDataRequest
      ],
      cancel_request: Proto.CancelMarketData
    },
    Proto.RealTimeBarsRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.RealTimeBarTick],
      cancel_request: Proto.CancelRealTimeBars
    },
    Proto.MarketDepthRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.MarketDepth, Proto.MarketDepthL2, Proto.RerouteMarketDepthRequest],
      cancel_request: Proto.CancelMarketDepth
    },
    Proto.TickByTickRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.TickByTickData],
      cancel_request: Proto.CancelTickByTick
    },
    Proto.CalculateImpliedVolatilityRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.TickOptionComputation],
      cancel_request: Proto.CancelCalculateImpliedVolatility
    },
    Proto.CalculateOptionPriceRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.TickOptionComputation],
      cancel_request: Proto.CancelCalculateOptionPrice
    },
    Proto.PnLRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.PnL],
      cancel_request: Proto.CancelPnL
    },
    Proto.PnLSingleRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.PnLSingle],
      cancel_request: Proto.CancelPnLSingle
    },
    Proto.WshMetaDataRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.WshMetaData],
      cancel_request: Proto.CancelWshMetaData
    },
    Proto.WshEventDataRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.WshEventData],
      cancel_request: Proto.CancelWshEventData
    },

    # Continuous stream types (correlation: :global -- no req_id)
    Proto.NewsBulletinsRequest => %{
      type: :stream,
      correlation: :global,
      responses: [Proto.NewsBulletin],
      cancel_request: Proto.CancelNewsBulletins
    },

    # -----------------------------------------------------------------------
    # Order lifecycle stream (correlation: :order_id)
    # -----------------------------------------------------------------------
    Proto.PlaceOrderRequest => %{
      type: :stream,
      correlation: :order_id,
      responses: [
        Proto.OpenOrder,
        Proto.OrderStatus,
        Proto.OrderBound,
        Proto.CommissionAndFeesReport,
        Proto.DeltaNeutralContract
      ],
      cancel_request: Proto.CancelOrderRequest
    },

    # -----------------------------------------------------------------------
    # Command types (fire-and-forget, no direct response)
    # Some commands (CancelOrder, GlobalCancel, ExerciseOptions) trigger
    # responses (e.g. OrderStatus) that route through the order's PlaceOrder
    # lifecycle stream rather than through a separate conversation.
    # -----------------------------------------------------------------------
    Proto.CancelOrderRequest => %{
      type: :command,
      correlation: :order_id,
      responses: []
    },
    Proto.GlobalCancelRequest => %{
      type: :command,
      correlation: :global,
      responses: []
    },
    Proto.ExerciseOptionsRequest => %{
      type: :command,
      correlation: :req_id,
      responses: []
    },
    Proto.MarketDataTypeRequest => %{
      type: :command,
      correlation: :global,
      responses: [Proto.MarketDataType]
    },
    Proto.SetServerLogLevelRequest => %{
      type: :command,
      correlation: :global,
      responses: []
    },
    Proto.AutoOpenOrdersRequest => %{
      type: :command,
      correlation: :global,
      responses: []
    },
    Proto.FARequest => %{
      type: :command,
      correlation: :global,
      responses: [Proto.ReceiveFA]
    },
    Proto.IdsRequest => %{
      type: :command,
      correlation: :global,
      responses: [Proto.NextValidId]
    },
    Proto.VerifyRequest => %{
      type: :command,
      correlation: :global,
      responses: [Proto.VerifyMessageApi]
    },
    Proto.VerifyMessageRequest => %{
      type: :command,
      correlation: :global,
      responses: [Proto.VerifyCompleted]
    },
    Proto.QueryDisplayGroupsRequest => %{
      type: :command,
      correlation: :req_id,
      responses: [Proto.DisplayGroupList]
    },
    Proto.SubscribeToGroupEventsRequest => %{
      type: :stream,
      correlation: :req_id,
      responses: [Proto.DisplayGroupUpdated],
      cancel_request: Proto.UnsubscribeFromGroupEventsRequest
    },
    Proto.UpdateDisplayGroupRequest => %{
      type: :command,
      correlation: :req_id,
      responses: []
    },
    Proto.ManagedAccountsRequest => %{
      type: :command,
      correlation: :global,
      responses: [Proto.ManagedAccounts]
    },
    Proto.StartApiRequest => %{
      type: :command,
      correlation: :global,
      responses: [Proto.ManagedAccounts, Proto.NextValidId]
    }
  }

  @doc """
  Returns all request modules that have a registered conversation.
  """
  @spec request_modules() :: [module()]
  def request_modules, do: Map.keys(@conversations)

  @doc """
  Returns the conversation shape for the given request module.

  ## Examples

      iex> IbEx.Client.Conversations.conversation_for(IbEx.Client.Proto.Protobuf.ContractDataRequest)
      {:ok, %{type: :bounded_stream, correlation: :req_id, responses: [IbEx.Client.Proto.Protobuf.ContractData], end_marker: IbEx.Client.Proto.Protobuf.ContractDataEnd, cancel_request: IbEx.Client.Proto.Protobuf.CancelContractData}}

  """
  @spec conversation_for(module()) :: {:ok, map()} | :error
  def conversation_for(request_module) do
    Map.fetch(@conversations, request_module)
  end

  @doc """
  Returns true if the given module is an end marker for any conversation.

  ## Examples

      iex> IbEx.Client.Conversations.end_marker?(IbEx.Client.Proto.Protobuf.ContractDataEnd)
      true

      iex> IbEx.Client.Conversations.end_marker?(IbEx.Client.Proto.Protobuf.ContractData)
      false

  """
  @spec end_marker?(module()) :: boolean()
  def end_marker?(module) do
    MapSet.member?(end_markers(), module)
  end

  @doc """
  Returns the cancel request module for the given request module, if one exists.

  ## Examples

      iex> IbEx.Client.Conversations.cancel_request_for(IbEx.Client.Proto.Protobuf.ContractDataRequest)
      {:ok, IbEx.Client.Proto.Protobuf.CancelContractData}

  """
  @spec cancel_request_for(module()) :: {:ok, module()} | :error
  def cancel_request_for(request_module) do
    case Map.fetch(@conversations, request_module) do
      {:ok, shape} -> Map.fetch(shape, :cancel_request)
      :error -> :error
    end
  end

  @doc """
  Returns the list of request modules that expect the given response module.

  ## Examples

      iex> IbEx.Client.Conversations.requests_for_response(IbEx.Client.Proto.Protobuf.ContractData)
      [IbEx.Client.Proto.Protobuf.ContractDataRequest]

  """
  @spec requests_for_response(module()) :: [module()]
  def requests_for_response(response_module) do
    Map.get(response_to_requests(), response_module, [])
  end

  @doc """
  Returns true if the given request module uses global correlation (no req_id).
  """
  @spec global_correlation?(module()) :: boolean()
  def global_correlation?(request_module) do
    case Map.fetch(@conversations, request_module) do
      {:ok, %{correlation: :global}} -> true
      _ -> false
    end
  end

  @doc """
  Registers a conversation in ETS based on the request module's correlation type.

  Looks up the conversation shape, determines the ETS key, allocates a req_id
  if needed, registers the entry via Subscriptions, and sets up a timeout timer.

  Returns `{:ok, key, req_id_or_nil}` on success or `:error` if the request
  module has no registered conversation.

  ## Parameters

    * `table_ref` -- the ETS table reference
    * `request_module` -- the proto request module (e.g. `Proto.ContractDataRequest`)
    * `from` -- the GenServer `from` reference for replying later
    * `timeout` -- timeout in milliseconds for the request timer
    * `client_pid` -- the Client pid to send the timeout message to

  """
  @spec register_request(reference(), module(), GenServer.from(), non_neg_integer(), pid()) ::
          {:ok, tuple(), non_neg_integer() | nil} | :error
  def register_request(table_ref, request_module, from, timeout, client_pid) do
    case conversation_for(request_module) do
      {:ok, shape} ->
        {key, req_id} = build_key(shape.correlation, table_ref, request_module)
        timer_ref = Process.send_after(client_pid, {:request_timeout, key}, timeout)
        Subscriptions.register_request(table_ref, key, from, timer_ref, request_module)
        {:ok, key, req_id}

      :error ->
        :error
    end
  end

  @doc """
  Registers a stream subscription in ETS for the given request module.

  Validates the conversation is a `:stream` type, allocates a req_id,
  monitors the subscriber process, and registers the stream entry via Subscriptions.

  Returns `{:ok, req_id, subscription_ref}` on success or `:error` if the
  request module is not a registered stream conversation.
  """
  @spec register_stream(reference(), module(), pid()) :: {:ok, non_neg_integer(), reference()} | :error
  def register_stream(table_ref, request_module, subscriber) do
    case conversation_for(request_module) do
      {:ok, %{type: :stream, correlation: correlation}} ->
        req_id = Subscriptions.allocate_request_id(table_ref)

        key =
          case correlation do
            :order_id -> {:order_id, req_id}
            _ -> {:request_id, req_id}
          end

        subscription_ref = make_ref()
        monitor_ref = Process.monitor(subscriber)

        Subscriptions.register_stream(table_ref, key, subscriber, monitor_ref, subscription_ref, request_module)
        {:ok, req_id, subscription_ref}

      _ ->
        :error
    end
  end

  defp build_key(:req_id, table_ref, _request_module) do
    req_id = Subscriptions.allocate_request_id(table_ref)
    {{:request_id, req_id}, req_id}
  end

  defp build_key(:global, _table_ref, request_module) do
    {{:global, request_module}, nil}
  end

  defp build_key(:order_id, table_ref, _request_module) do
    order_id = Subscriptions.allocate_request_id(table_ref)
    {{:order_id, order_id}, order_id}
  end

  defp end_markers do
    @conversations
    |> Enum.flat_map(fn {_req, shape} ->
      case Map.get(shape, :end_marker) do
        nil -> []
        marker -> [marker]
      end
    end)
    |> MapSet.new()
  end

  defp response_to_requests do
    @conversations
    |> Enum.flat_map(fn {req, shape} ->
      all_responses = shape.responses ++ List.wrap(Map.get(shape, :end_marker))
      Enum.map(all_responses, fn resp -> {resp, req} end)
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end
end
