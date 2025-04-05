defmodule IbEx.Client.Messages.MatchingSymbols.Request do
  @moduledoc """
  Request message for symbol to Contract lookups in IBKR
  """

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defstruct pattern: nil, request_id: nil, message_id: nil

  def new(pattern) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id, pattern: pattern}}

      _ ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.request_id, msg.pattern])
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "--> MatchingSymbols{id: #{msg.message_id}, request_id: #{msg.request_id}, pattern: #{msg.pattern}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    # Subscription based on request_id, can handle multiple requests
    def subscribe(msg, pid, table_ref) do
      request_id = Subscriptions.subscribe_by_request_id(table_ref, pid)
      {:ok, %{msg | request_id: request_id}}
    end

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
