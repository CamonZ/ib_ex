defmodule IbEx.Client.Conversations do
  @moduledoc """
  Declarative registry of TWS conversation shapes.

  Maps each request proto module to its conversation metadata:
  type, correlation method, expected response types, end marker,
  and cancel request module.

  Provides compile-time derived indexes for efficient lookup.
  """

  alias IbEx.Client.Proto.Protobuf, as: Proto

  @conversations %{
    Proto.ContractDataRequest => %{
      type: :bounded_stream,
      correlation: :req_id,
      responses: [Proto.ContractData],
      end_marker: Proto.ContractDataEnd,
      cancel_request: Proto.CancelContractData
    },
    Proto.MatchingSymbolsRequest => %{
      type: :request_response,
      correlation: :req_id,
      responses: [Proto.SymbolSamples]
    }
  }

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
