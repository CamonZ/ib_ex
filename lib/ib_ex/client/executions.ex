defmodule IbEx.Client.Executions do
  @moduledoc """
  Thematic module for execution operations.

  Provides high-level functions for requesting execution details. This module
  is stateless -- it builds proto request structs and delegates to
  `Client.request/3`.

  ## Functions

  * `request/3` - Requests execution details, optionally filtered by an
    `ExecutionFilter` (bounded stream: accumulates `ExecutionDetails` responses,
    ends with `ExecutionDetailsEnd`).
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Mapper
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.ExecutionsFilter, as: DomainFilter

  @doc """
  Requests execution details, optionally filtered.

  Sends an `ExecutionRequest` through `Client.request/3` using req_id correlation.
  The response is a bounded stream that accumulates `ExecutionDetails` protos
  and ends with an `ExecutionDetailsEnd` marker.

  Returns `{:ok, [%Proto.ExecutionDetails{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Arguments

  * `client` - The client pid.
  * `filter` - An optional `ExecutionFilter` (proto or domain) or `nil` (default: `nil`).
  * `opts` - Keyword options.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      # Request all executions (no filter)
      {:ok, executions} = Executions.request(client)

      # Request with a proto filter
      filter = %Proto.ExecutionFilter{symbol: "AAPL", side: "BUY"}
      {:ok, executions} = Executions.request(client, filter)

      # Request with a domain filter
      {:ok, domain_filter} = IbEx.Client.Types.ExecutionsFilter.new(symbol: "AAPL", side: "BUY")
      {:ok, executions} = Executions.request(client, domain_filter)

  """
  @spec request(pid(), struct() | nil, keyword()) :: {:ok, list()} | {:error, any()}
  def request(client, filter \\ nil, opts \\ [])

  def request(client, nil, opts) do
    request = %Proto.ExecutionRequest{}
    Client.request(client, request, opts)
  end

  def request(client, %Proto.ExecutionFilter{} = proto_filter, opts) do
    request = %Proto.ExecutionRequest{execution_filter: proto_filter}
    Client.request(client, request, opts)
  end

  def request(client, %DomainFilter{} = filter, opts) do
    request(client, Mapper.to_proto(filter), opts)
  end
end
