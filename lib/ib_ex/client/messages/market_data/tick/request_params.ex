defmodule IbEx.Client.Messages.MarketData.Tick.RequestParams do
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

  alias IbEx.Client.Utils

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([request_id, min_tick_str, bbo_exchange_str, snapshot_perms_str]) do
    msg = %__MODULE__{
      request_id: request_id,
      min_tick: Utils.to_float(min_tick_str),
      bbo_exchange: bbo_exchange_str,
      snapshot_permissions: Utils.to_integer(snapshot_perms_str)
    }

    {:ok, msg}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- %MarketData.Tick.RequestParams{request_id: #{msg.request_id}, min_tick: #{msg.min_tick}, bbo_exchange: #{msg.bbo_exchange}, snapshot_permissions: #{msg.snapshot_permissions}}"
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
