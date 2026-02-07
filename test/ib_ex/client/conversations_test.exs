defmodule IbEx.Client.ConversationsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Conversations
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

    test "returns :error for unknown modules" do
      assert :error = Conversations.conversation_for(SomeUnknownModule)
    end
  end

  describe "end_marker?/1" do
    test "returns true for ContractDataEnd" do
      assert Conversations.end_marker?(Proto.ContractDataEnd)
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

    test "returns empty list for unknown response module" do
      assert Conversations.requests_for_response(SomeUnknownModule) == []
    end
  end

  describe "cross-references with @message_ids and @decoders" do
    alias IbEx.Client.Messages.Requests
    alias IbEx.Client.Messages.Responses

    test "all conversation request modules have a message_id in Requests" do
      {:ok, contract_data_shape} = Conversations.conversation_for(Proto.ContractDataRequest)
      assert {:ok, _id} = Requests.message_id_for(Proto.ContractDataRequest)

      {:ok, matching_symbols_shape} = Conversations.conversation_for(Proto.MatchingSymbolsRequest)
      assert {:ok, _id} = Requests.message_id_for(Proto.MatchingSymbolsRequest)

      # Also verify cancel requests have message_ids
      assert {:ok, _id} = Requests.message_id_for(contract_data_shape.cancel_request)

      # MatchingSymbolsRequest has no cancel_request
      refute Map.has_key?(matching_symbols_shape, :cancel_request)
    end

    test "all conversation response modules are in the decoders map" do
      # ContractData is decoded at msg_id 10 (and 18 for bonds)
      proto_payload = %Proto.ContractData{req_id: 1} |> Protobuf.encode()
      wire_msg = <<10 + 200::big-integer-size(32), proto_payload::binary>>
      assert {:ok, %Proto.ContractData{}} = Responses.parse(wire_msg, :connected, false)

      # ContractDataEnd is decoded at msg_id 52
      proto_payload = %Proto.ContractDataEnd{req_id: 1} |> Protobuf.encode()
      wire_msg = <<52 + 200::big-integer-size(32), proto_payload::binary>>
      assert {:ok, %Proto.ContractDataEnd{}} = Responses.parse(wire_msg, :connected, false)

      # SymbolSamples is decoded at msg_id 79
      proto_payload = %Proto.SymbolSamples{req_id: 1} |> Protobuf.encode()
      wire_msg = <<79 + 200::big-integer-size(32), proto_payload::binary>>
      assert {:ok, %Proto.SymbolSamples{}} = Responses.parse(wire_msg, :connected, false)
    end
  end
end
