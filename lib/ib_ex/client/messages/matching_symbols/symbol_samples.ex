defmodule IbEx.Client.Messages.MatchingSymbols.SymbolSamples do
  @moduledoc """
  Response message from requesting a list of matching symbols

  Within the contract descriptions is the list of contracts that match the specified
  pattern.
  """

  defstruct request_id: nil, contracts: []

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- SymbolSamples{request_id: #{msg.request_id}, contracts: #{inspect(msg.contracts)}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
