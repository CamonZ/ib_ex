defmodule IbEx.Client.Messages.MarketData.RequestMarketDataType do
  @moduledoc """
  Request to switch market data type 


  The input parameters are the following:

  * market_data_type: type of market data to retrieve. Possible values: 
    - :live
    - :frozen
    - :delayed
    - :delayed_frozen

  """

  @version 1

  defstruct message_id: nil,
            request_id: nil,
            version: @version,
            market_data_type: :live

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Messages.MarketData.MarketDataType
  alias IbEx.Client.Protocols.Traceable

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          version: non_neg_integer(),
          market_data_type: 1..4
        }

  @spec new(:live | :frozen | :delayed | :delayed_frozen) ::
          {:ok, t()} | {:error, :not_implemented}
  def new(market_data_type) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {
          :ok,
          %__MODULE__{
            message_id: message_id,
            market_data_type: MarketDataType.atom_to_integer(market_data_type)
          }
        }

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      fields = [
        msg.message_id,
        msg.version,
        msg.market_data_type
      ]

      Base.build(fields)
    end
  end

  defimpl Traceable, for: __MODULE__ do
    alias IbEx.Client.Messages.MarketData.MarketDataType

    def to_s(msg) do
      """
      --> MarketData.RequestMarketDataType{
        market_data_type: :#{MarketDataType.integer_to_atom(msg.market_data_type)}
      }
      """
    end
  end

  defimpl IbEx.Client.Protocols.Subscribable, for: __MODULE__ do
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
