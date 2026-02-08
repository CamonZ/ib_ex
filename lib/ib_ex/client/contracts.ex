defmodule IbEx.Client.Contracts do
  @moduledoc """
  Thematic module for contract-related operations.

  Provides high-level functions for querying contract details and searching
  for matching symbols. This module is stateless -- it builds proto request
  structs and delegates to `Client.request/3` for dispatch.

  ## Functions

  * `request_details/3` - Fetches full contract details for a given contract
    (bounded stream: accumulates multiple ContractData responses).
  * `matching_symbols/3` - Searches for symbols matching a pattern string
    (single request/response).
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract
  alias IbEx.Client.Types.ContractDescription, as: DomainContractDescription

  @doc """
  Requests contract details for the given contract.

  Accepts domain contracts, proto contracts, or contract descriptions (domain or proto)
  and sends a `ContractDataRequest` through `Client.request/3`.

  Returns `{:ok, [%Proto.ContractData{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Examples

      contract = %IbEx.Client.Types.Contract{symbol: "AAPL", security_type: "STK", currency: "USD"}
      {:ok, contract_data_list} = Contracts.request_details(client, contract)

  """
  @spec request_details(pid(), struct(), keyword()) :: {:ok, list()} | {:error, any()}
  def request_details(client, contract, opts \\ [])

  def request_details(client, %Proto.ContractDescription{contract: contract}, opts) do
    request_details(client, contract, opts)
  end

  def request_details(client, %DomainContractDescription{contract: contract}, opts) do
    request_details(client, contract, opts)
  end

  def request_details(client, %Proto.Contract{} = proto_contract, opts) do
    request = %Proto.ContractDataRequest{contract: proto_contract}
    Client.request(client, request, opts)
  end

  def request_details(client, %DomainContract{} = contract, opts) do
    proto_contract = Mapper.to_proto(contract)
    request = %Proto.ContractDataRequest{contract: proto_contract}
    Client.request(client, request, opts)
  end

  @doc """
  Searches for symbols matching the given pattern string.

  Builds a `MatchingSymbolsRequest` with the pattern and sends it through
  `Client.request/3`.

  Returns `{:ok, %Proto.SymbolSamples{}}` on success, or `{:error, reason}` on failure.

  ## Examples

      {:ok, %Proto.SymbolSamples{} = samples} = Contracts.matching_symbols(client, "AAPL")

  """
  @spec matching_symbols(pid(), String.t(), keyword()) :: {:ok, struct()} | {:error, any()}
  def matching_symbols(client, pattern, opts \\ []) do
    request = %Proto.MatchingSymbolsRequest{pattern: pattern}
    Client.request(client, request, opts)
  end
end
