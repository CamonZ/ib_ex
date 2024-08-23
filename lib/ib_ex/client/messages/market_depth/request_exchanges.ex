defmodule IbEx.Client.Messages.MarketDepth.RequestExchanges do
  @moduledoc """
  Requests the different available exchanges for market depth data (Orderbook)
  """

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Subscribable

  defstruct message_id: nil

  def new do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id}}

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(_msg, _opts) do
      "--> RequestExchanges{}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Messages.MarketDepth.Exchanges
    alias IbEx.Client.Subscriptions

    def subscribe(msg, pid, table_ref) do
      :ok = Subscriptions.subscribe_by_modules(table_ref, [Exchanges], pid)
      {:ok, msg}
    end

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
