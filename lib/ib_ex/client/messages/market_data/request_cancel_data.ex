defmodule IbEx.Client.Messages.MarketData.RequestCancelData do
  @moduledoc """
  Requests to cancel the subscription to Market Data updates

  The input parameter is:
  * Request id
  """

  @version 2

  defstruct message_id: nil, version: @version, request_id: ""

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          version: non_neg_integer(),
          request_id: non_neg_integer()
        }

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  @spec new() :: {:ok, t()} | {:error, :not_implemented}
  def new() do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} -> {:ok, %__MODULE__{message_id: id}}
      :error -> {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.version, msg.request_id])
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "--> %MarketData.RequestCancelData{request_id: #{msg.request_id}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    # Subscription based on request_id, can handle multiple requests
    def subscribe(msg, pid, table_ref) do
      {:ok, request_id} = Subscriptions.reverse_lookup(table_ref, pid)
      :ets.delete(table_ref, request_id)

      {:ok, %{msg | request_id: request_id}}
    end

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
