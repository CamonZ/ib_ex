defmodule IbEx.Client.Messages.MarketDepth.Exchanges do
  @moduledoc """
  Response to the RequestExchanges message

  Receives a list of different exchanges from which to request market depth data
  """

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defstruct items: nil

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %MarketDepth.Exchanges{items: #{inspect(msg.items)}}
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Messages.MarketDepth.Exchanges
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(_msg, table_ref) do
      Subscriptions.lookup(table_ref, Exchanges)
    end
  end
end
