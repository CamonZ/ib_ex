defmodule IbEx.Client.Messages.Executions.Request do
  @moduledoc """
  Message used to request the executions of a given trading day.

  According to the API docs, it's possible to get the executions of previous days by
  opening in TWS the trade log and selecting previous days in the date range.

  The input parameters to create this message are:

  request_id: unique identifier for the request
  executions_filter: Optional %ExecutionsFilter struct with the specifications of which executions to return
  """

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Types.ExecutionsFilter

  @version 3

  defstruct message_id: nil, version: @version, request_id: nil, filter: nil

  @type t :: %__MODULE__{
          message_id: integer(),
          request_id: non_neg_integer(),
          filter: ExecutionsFilter.t()
        }

  @spec new(non_neg_integer(), ExecutionsFilter.t()) :: {:ok, t()} | {:error, :not_implemented}
  def new(request_id, executions_filter \\ %ExecutionsFilter{}) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {
          :ok,
          %__MODULE__{
            message_id: message_id,
            request_id: request_id,
            filter: executions_filter
          }
        }

      _ ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      fields = [
        msg.message_id,
        msg.version,
        msg.request_id,
        msg.filter.client_id,
        msg.filter.account_id,
        msg.filter.time,
        msg.filter.symbol,
        msg.filter.security_type,
        msg.filter.exchange,
        msg.filter.side
      ]

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      --> Executions.Request{
        message_id: #{msg.message_id},
        request_id: #{msg.request_id},
        filter: #{inspect(msg.filter)}
      }
      """
    end
  end
end
