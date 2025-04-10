defmodule IbEx.Client.Messages.TickByTickData.CancelTickByTickData do
  @moduledoc """
  Represents a request to cancel tick by tick data stream identified by its request id.
  """

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Protocols.Subscribable

  defstruct message_id: nil, request_id: nil

  @type t :: %__MODULE__{
          message_id: non_neg_integer() | nil,
          request_id: non_neg_integer() | nil
        }

  @spec new(non_neg_integer()) :: {:ok, t()} | {:error, :not_implemented}
  def new(request_id) when is_integer(request_id) and request_id > 0 do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id, request_id: request_id}}

      :error ->
        {:error, :not_implemented}
    end
  end

  def new(_) do
    {:error, :invalid_args}
  end

  defimpl String.Chars, for: __MODULE__ do
    def to_string(msg) do
      Base.build([msg.message_id, msg.request_id])
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "--> CancelTickByTickData{message_id: #{msg.message_id}, request_id: #{msg.request_id}}"
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
