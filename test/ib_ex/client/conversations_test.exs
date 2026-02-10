defmodule IbEx.Client.ConversationsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Conversations
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Messages.Responses
  alias IbEx.Client.Proto.Protobuf, as: Proto

  describe "conversation_for/1" do
    test "returns bounded_stream shape for ContractDataRequest" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.ContractDataRequest)

      assert shape.type == :bounded_stream
      assert shape.correlation == :req_id
      assert shape.responses == [Proto.ContractData]
      assert shape.end_marker == Proto.ContractDataEnd
      assert shape.cancel_request == Proto.CancelContractData
    end

    test "returns request_response shape for MatchingSymbolsRequest" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.MatchingSymbolsRequest)

      assert shape.type == :request_response
      assert shape.correlation == :req_id
      assert shape.responses == [Proto.SymbolSamples]
      refute Map.has_key?(shape, :end_marker)
      refute Map.has_key?(shape, :cancel_request)
    end

    test "returns stream shape for MarketDataRequest with full tick types" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.MarketDataRequest)

      assert shape.type == :stream
      assert shape.correlation == :req_id
      assert Proto.TickPrice in shape.responses
      assert Proto.TickSize in shape.responses
      assert Proto.TickGeneric in shape.responses
      assert Proto.TickString in shape.responses
      assert Proto.TickOptionComputation in shape.responses
      assert shape.cancel_request == Proto.CancelMarketData
    end

    test "returns global correlation for CurrentTimeRequest" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.CurrentTimeRequest)

      assert shape.type == :request_response
      assert shape.correlation == :global
      assert shape.responses == [Proto.CurrentTime]
    end

    test "returns global bounded_stream for OpenOrdersRequest" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.OpenOrdersRequest)

      assert shape.type == :bounded_stream
      assert shape.correlation == :global
      assert shape.responses == [Proto.OpenOrder]
      assert shape.end_marker == Proto.OpenOrdersEnd
    end

    test "returns global bounded_stream for PositionsRequest" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.PositionsRequest)

      assert shape.type == :bounded_stream
      assert shape.correlation == :global
      assert shape.responses == [Proto.Position]
      assert shape.end_marker == Proto.PositionEnd
      assert shape.cancel_request == Proto.CancelPositions
    end

    test "returns global bounded_stream for AccountDataRequest" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.AccountDataRequest)

      assert shape.type == :bounded_stream
      assert shape.correlation == :global
      assert shape.responses == [Proto.AccountValue, Proto.PortfolioValue, Proto.AccountUpdateTime]
      assert shape.end_marker == Proto.AccountDataEnd
    end

    test "returns global bounded_stream for CompletedOrdersRequest" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.CompletedOrdersRequest)

      assert shape.type == :bounded_stream
      assert shape.correlation == :global
      assert shape.responses == [Proto.CompletedOrder]
      assert shape.end_marker == Proto.CompletedOrdersEnd
    end

    test "returns command shape for fire-and-forget requests" do
      assert {:ok, shape} = Conversations.conversation_for(Proto.GlobalCancelRequest)
      assert shape.type == :command
      assert shape.correlation == :global
    end

    test "returns :error for unknown modules" do
      assert :error = Conversations.conversation_for(SomeUnknownModule)
    end
  end

  describe "end_marker?/1" do
    test "returns true for ContractDataEnd" do
      assert Conversations.end_marker?(Proto.ContractDataEnd)
    end

    test "returns true for all registered end markers" do
      end_markers = [
        Proto.ContractDataEnd,
        Proto.ExecutionDetailsEnd,
        Proto.HistoricalDataEnd,
        Proto.AccountSummaryEnd,
        Proto.PositionMultiEnd,
        Proto.AccountUpdateMultiEnd,
        Proto.SecDefOptParameterEnd,
        Proto.HistoricalNewsEnd,
        Proto.ReplaceFAEnd,
        Proto.OpenOrdersEnd,
        Proto.AccountDataEnd,
        Proto.PositionEnd,
        Proto.CompletedOrdersEnd
      ]

      for marker <- end_markers do
        assert Conversations.end_marker?(marker),
               "Expected #{inspect(marker)} to be recognized as an end marker"
      end
    end

    test "returns false for ContractData (a regular response, not an end marker)" do
      refute Conversations.end_marker?(Proto.ContractData)
    end

    test "returns false for SymbolSamples (request_response has no end marker)" do
      refute Conversations.end_marker?(Proto.SymbolSamples)
    end

    test "returns false for an unknown module" do
      refute Conversations.end_marker?(SomeUnknownModule)
    end
  end

  describe "cancel_request_for/1" do
    test "returns cancel module for ContractDataRequest" do
      assert {:ok, Proto.CancelContractData} = Conversations.cancel_request_for(Proto.ContractDataRequest)
    end

    test "returns cancel module for stream types" do
      assert {:ok, Proto.CancelMarketData} = Conversations.cancel_request_for(Proto.MarketDataRequest)
      assert {:ok, Proto.CancelRealTimeBars} = Conversations.cancel_request_for(Proto.RealTimeBarsRequest)
      assert {:ok, Proto.CancelMarketDepth} = Conversations.cancel_request_for(Proto.MarketDepthRequest)
      assert {:ok, Proto.CancelTickByTick} = Conversations.cancel_request_for(Proto.TickByTickRequest)
      assert {:ok, Proto.CancelPnL} = Conversations.cancel_request_for(Proto.PnLRequest)
      assert {:ok, Proto.CancelPnLSingle} = Conversations.cancel_request_for(Proto.PnLSingleRequest)
      assert {:ok, Proto.CancelWshMetaData} = Conversations.cancel_request_for(Proto.WshMetaDataRequest)
      assert {:ok, Proto.CancelWshEventData} = Conversations.cancel_request_for(Proto.WshEventDataRequest)
    end

    test "returns :error for MatchingSymbolsRequest (no cancel request)" do
      assert :error = Conversations.cancel_request_for(Proto.MatchingSymbolsRequest)
    end

    test "returns :error for unknown modules" do
      assert :error = Conversations.cancel_request_for(SomeUnknownModule)
    end
  end

  describe "requests_for_response/1" do
    test "returns [ContractDataRequest] for ContractData response" do
      assert Conversations.requests_for_response(Proto.ContractData) == [Proto.ContractDataRequest]
    end

    test "returns [ContractDataRequest] for ContractDataEnd end marker" do
      assert Conversations.requests_for_response(Proto.ContractDataEnd) == [Proto.ContractDataRequest]
    end

    test "returns [MatchingSymbolsRequest] for SymbolSamples response" do
      assert Conversations.requests_for_response(Proto.SymbolSamples) == [Proto.MatchingSymbolsRequest]
    end

    test "returns multiple request modules for shared response types" do
      # OpenOrder is a response for both OpenOrdersRequest and AllOpenOrdersRequest
      request_modules = Conversations.requests_for_response(Proto.OpenOrder)
      assert Proto.OpenOrdersRequest in request_modules
      assert Proto.AllOpenOrdersRequest in request_modules
    end

    test "returns empty list for unknown response module" do
      assert Conversations.requests_for_response(SomeUnknownModule) == []
    end
  end

  describe "global_correlation?/1" do
    test "returns true for request modules without req_id" do
      assert Conversations.global_correlation?(Proto.CurrentTimeRequest)
      assert Conversations.global_correlation?(Proto.CurrentTimeInMillisRequest)
      assert Conversations.global_correlation?(Proto.ScannerParametersRequest)
      assert Conversations.global_correlation?(Proto.NewsProvidersRequest)
      assert Conversations.global_correlation?(Proto.FamilyCodesRequest)
      assert Conversations.global_correlation?(Proto.MarketDepthExchangesRequest)
      assert Conversations.global_correlation?(Proto.MarketRuleRequest)
      assert Conversations.global_correlation?(Proto.OpenOrdersRequest)
      assert Conversations.global_correlation?(Proto.AllOpenOrdersRequest)
      assert Conversations.global_correlation?(Proto.AccountDataRequest)
      assert Conversations.global_correlation?(Proto.PositionsRequest)
      assert Conversations.global_correlation?(Proto.CompletedOrdersRequest)
      assert Conversations.global_correlation?(Proto.NewsBulletinsRequest)
    end

    test "returns false for request modules with req_id" do
      refute Conversations.global_correlation?(Proto.ContractDataRequest)
      refute Conversations.global_correlation?(Proto.MatchingSymbolsRequest)
      refute Conversations.global_correlation?(Proto.MarketDataRequest)
      refute Conversations.global_correlation?(Proto.HistoricalDataRequest)
    end

    test "returns false for unknown modules" do
      refute Conversations.global_correlation?(SomeUnknownModule)
    end
  end

  describe "cross-reference: @message_ids coverage" do
    # Cancel request modules in @message_ids are not conversation initiators;
    # they appear as cancel_request values within conversation entries.
    @cancel_modules [
      Proto.CancelMarketData,
      Proto.CancelMarketDepth,
      Proto.CancelNewsBulletins,
      Proto.CancelScannerSubscription,
      Proto.CancelHistoricalData,
      Proto.CancelRealTimeBars,
      Proto.CancelFundamentalsData,
      Proto.CancelCalculateImpliedVolatility,
      Proto.CancelCalculateOptionPrice,
      Proto.CancelAccountSummary,
      Proto.CancelPositions,
      Proto.CancelPositionsMulti,
      Proto.CancelAccountUpdatesMulti,
      Proto.CancelHistogramData,
      Proto.CancelHeadTimestamp,
      Proto.CancelPnL,
      Proto.CancelPnLSingle,
      Proto.CancelTickByTick,
      Proto.CancelWshMetaData,
      Proto.CancelWshEventData,
      Proto.CancelContractData,
      Proto.CancelHistoricalTicks,
      Proto.UnsubscribeFromGroupEventsRequest
    ]

    test "every non-cancel request module in @message_ids has a @conversations entry" do
      request_modules = Requests.request_modules()
      conversation_modules = MapSet.new(Conversations.request_modules())

      missing =
        request_modules
        |> Enum.reject(&(&1 in @cancel_modules))
        |> Enum.reject(&MapSet.member?(conversation_modules, &1))

      assert missing == [],
             "The following request modules in @message_ids have no @conversations entry:\n" <>
               Enum.map_join(missing, "\n", &"  - #{inspect(&1)}")
    end

    test "every cancel_request value in @conversations has a @message_ids entry" do
      cancel_modules =
        Conversations.request_modules()
        |> Enum.map(&Conversations.cancel_request_for/1)
        |> Enum.flat_map(fn
          {:ok, mod} -> [mod]
          :error -> []
        end)
        |> Enum.uniq()

      missing =
        Enum.reject(cancel_modules, fn mod ->
          {:ok, _} = Requests.message_id_for(mod)
          true
        end)

      assert missing == [],
             "The following cancel request modules have no @message_ids entry:\n" <>
               Enum.map_join(missing, "\n", &"  - #{inspect(&1)}")
    end
  end

  describe "cross-reference: end markers in @decoders" do
    # All end marker modules that appear in the @decoders response map
    @end_marker_decoder_modules [
      Proto.ContractDataEnd,
      Proto.OpenOrdersEnd,
      Proto.AccountDataEnd,
      Proto.ExecutionDetailsEnd,
      Proto.TickSnapshotEnd,
      Proto.PositionEnd,
      Proto.AccountSummaryEnd,
      Proto.PositionMultiEnd,
      Proto.AccountUpdateMultiEnd,
      Proto.SecDefOptParameterEnd,
      Proto.HistoricalNewsEnd,
      Proto.CompletedOrdersEnd,
      Proto.ReplaceFAEnd,
      Proto.HistoricalDataEnd
    ]

    test "every end marker module in @decoders is referenced by a bounded stream conversation entry" do
      all_decoder_modules = Responses.decoder_modules()

      # Identify which decoder modules are end markers (name ends with "End")
      end_marker_decoders =
        all_decoder_modules
        |> Enum.filter(fn mod ->
          mod_name = mod |> Module.split() |> List.last()
          String.ends_with?(mod_name, "End")
        end)

      # Verify our list is complete
      assert MapSet.new(end_marker_decoders) == MapSet.new(@end_marker_decoder_modules),
             "End marker decoder list mismatch. " <>
               "In decoders: #{inspect(end_marker_decoders)}, expected: #{inspect(@end_marker_decoder_modules)}"

      # Every end marker decoder must be referenced in a conversation
      unreferenced =
        Enum.reject(end_marker_decoders, fn marker ->
          # Check if it appears as an end_marker or in responses of any conversation
          Conversations.end_marker?(marker) or
            Enum.any?(Conversations.request_modules(), fn req_mod ->
              {:ok, shape} = Conversations.conversation_for(req_mod)
              marker in shape.responses
            end)
        end)

      assert unreferenced == [],
             "The following end marker modules in @decoders are not referenced by any conversation:\n" <>
               Enum.map_join(unreferenced, "\n", &"  - #{inspect(&1)}")
    end
  end

  describe "conversation type distribution" do
    test "registry contains all expected conversation types" do
      types =
        Conversations.request_modules()
        |> Enum.map(fn mod ->
          {:ok, shape} = Conversations.conversation_for(mod)
          shape.type
        end)
        |> Enum.uniq()
        |> Enum.sort()

      assert :bounded_stream in types
      assert :command in types
      assert :request_response in types
      assert :stream in types
    end

    test "registry contains both :req_id and :global correlation methods" do
      correlations =
        Conversations.request_modules()
        |> Enum.map(fn mod ->
          {:ok, shape} = Conversations.conversation_for(mod)
          shape.correlation
        end)
        |> Enum.uniq()
        |> Enum.sort()

      assert correlations == [:global, :order_id, :req_id]
    end
  end

  describe "register_request/5" do
    alias IbEx.Client.Subscriptions

    setup do
      table_ref = Subscriptions.initialize()
      %{table_ref: table_ref}
    end

    test "registers a :req_id conversation with {:request_id, N} key", %{table_ref: table_ref} do
      from = {self(), make_ref()}

      assert {:ok, key, req_id} =
               Conversations.register_request(table_ref, Proto.MatchingSymbolsRequest, from, 5_000, self())

      assert key == {:request_id, 1}
      assert req_id == 1

      assert {:ok, entry} = Subscriptions.lookup(table_ref, key)
      assert entry.type == :request
      assert entry.from == from
      refute Map.has_key?(entry, :buffer)
      assert entry.request_module == Proto.MatchingSymbolsRequest
      assert is_reference(entry.timer_ref)
    end

    test "registers a :global conversation with {:global, module} key", %{table_ref: table_ref} do
      from = {self(), make_ref()}

      assert {:ok, key, nil} =
               Conversations.register_request(table_ref, Proto.CurrentTimeRequest, from, 5_000, self())

      assert key == {:global, Proto.CurrentTimeRequest}

      assert {:ok, entry} = Subscriptions.lookup(table_ref, key)
      assert entry.type == :request
      assert entry.from == from
      assert entry.request_module == Proto.CurrentTimeRequest
    end

    test "registers an :order_id conversation with {:order_id, N} key", %{table_ref: table_ref} do
      from = {self(), make_ref()}

      assert {:ok, key, order_id} =
               Conversations.register_request(table_ref, Proto.PlaceOrderRequest, from, 5_000, self())

      assert key == {:order_id, 1}
      assert order_id == 1

      assert {:ok, entry} = Subscriptions.lookup(table_ref, key)
      assert entry.type == :request
      assert entry.request_module == Proto.PlaceOrderRequest
    end

    test "allocates incrementing req_ids for successive :req_id registrations", %{table_ref: table_ref} do
      from = {self(), make_ref()}

      assert {:ok, {:request_id, 1}, 1} =
               Conversations.register_request(table_ref, Proto.MatchingSymbolsRequest, from, 5_000, self())

      assert {:ok, {:request_id, 2}, 2} =
               Conversations.register_request(table_ref, Proto.HeadTimestampRequest, from, 5_000, self())
    end

    test "returns :error for unknown request module", %{table_ref: table_ref} do
      from = {self(), make_ref()}

      assert :error = Conversations.register_request(table_ref, SomeUnknownModule, from, 5_000, self())
    end

    test "sets up a timeout timer that sends {:request_timeout, key}", %{table_ref: table_ref} do
      from = {self(), make_ref()}

      assert {:ok, key, _req_id} =
               Conversations.register_request(table_ref, Proto.MatchingSymbolsRequest, from, 50, self())

      assert_receive {:request_timeout, ^key}, 200
    end
  end

  describe "register_stream/3" do
    alias IbEx.Client.Subscriptions

    setup do
      table_ref = Subscriptions.initialize()
      %{table_ref: table_ref}
    end

    test "registers a stream subscription with {:request_id, N} key", %{table_ref: table_ref} do
      assert {:ok, req_id, subscription_ref} =
               Conversations.register_stream(table_ref, Proto.MarketDataRequest, self())

      assert req_id == 1
      assert is_reference(subscription_ref)

      assert {:ok, entry} = Subscriptions.lookup(table_ref, {:request_id, 1})
      assert entry.type == :stream
      assert entry.subscriber == self()
      assert entry.subscription_ref == subscription_ref
      assert entry.request_module == Proto.MarketDataRequest
      assert is_reference(entry.monitor_ref)
    end

    test "returns :error for non-stream conversation types", %{table_ref: table_ref} do
      assert :error = Conversations.register_stream(table_ref, Proto.MatchingSymbolsRequest, self())
      assert :error = Conversations.register_stream(table_ref, Proto.ContractDataRequest, self())
      assert :error = Conversations.register_stream(table_ref, Proto.GlobalCancelRequest, self())
    end

    test "returns :error for unknown modules", %{table_ref: table_ref} do
      assert :error = Conversations.register_stream(table_ref, SomeUnknownModule, self())
    end

    test "monitors the subscriber process", %{table_ref: table_ref} do
      assert {:ok, _req_id, _sub_ref} =
               Conversations.register_stream(table_ref, Proto.MarketDataRequest, self())

      assert {:ok, entry} = Subscriptions.lookup(table_ref, {:request_id, 1})
      assert is_reference(entry.monitor_ref)
    end
  end
end
