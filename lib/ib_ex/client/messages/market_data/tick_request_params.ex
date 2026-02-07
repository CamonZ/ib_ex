defmodule IbEx.Client.Messages.MarketData.TickRequestParams do
  @moduledoc """
  One of the subscription messages coming from subscribing to
  the market data request.

  Represents the exchange map of a particular contract?
  """

  defstruct request_id: nil,
            min_tick: nil,
            bbo_exchange: nil,
            snapshot_permissions: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          min_tick: float() | nil,
          bbo_exchange: String.t(),
          snapshot_permissions: non_neg_integer() | nil
        }

  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %MarketData.TickRequestParams{request_id: #{msg.request_id}, min_tick: #{msg.min_tick}, bbo_exchange: #{msg.bbo_exchange}, snapshot_permissions: #{msg.snapshot_permissions}}"
    end
  end

  defimpl IbEx.Client.Protocols.Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
