defmodule IbEx.Client.Messages.MarketData.RequestOptionChain do
  @moduledoc """
  Request to get option chain for the given underlying.
  """

  defstruct message_id: nil,
            request_id: nil,
            underlying_symbol: nil,
            fut_fop_exchange: nil,
            underlying_sec_type: nil,
            underlying_conid: nil

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Subscribable

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          underlying_symbol: binary(),
          fut_fop_exchange: binary(),
          underlying_sec_type: binary(),
          underlying_conid: binary()
        }

  @spec new(list() | map()) :: {:ok, t()} | {:error, :request_message_not_implemented}
  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {:ok, struct(__MODULE__, Map.put(attrs, :message_id, message_id))}

      :error ->
        {:error, :request_message_not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      [
        msg.message_id,
        msg.request_id,
        msg.underlying_symbol,
        msg.fut_fop_exchange,
        msg.underlying_sec_type,
        msg.underlying_conid
      ]
      |> Base.build()
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      --> MarketData.RequestOptionChain{
        request_id: #{msg.request_id},
        underlying_symbol: #{msg.underlying_symbol},
        fut_fop_exchange: #{msg.fut_fop_exchange},
        underlying_sec_type: #{msg.underlying_sec_type},
        underlying_conid: #{msg.underlying_conid},
      }
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    # Subscription based on request_id, can handle multiple requests
    def subscribe(msg, pid, table_ref) do
      request_id = Subscriptions.subscribe_by_request_id(table_ref, pid)
      {:ok, %{msg | request_id: request_id}}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, to_string(msg.request_id))
    end
  end
end
