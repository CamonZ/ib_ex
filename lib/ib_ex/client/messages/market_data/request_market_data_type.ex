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

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          version: non_neg_integer(),
          market_data_type: 1..4
        }

  @spec new(non_neg_integer(), :live | :frozen | :delayed | :delayed_frozen) ::
          {:ok, t()} | {:error, :not_implemented}
  def new(request_id, market_data_type) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {
          :ok,
          %__MODULE__{
            message_id: message_id,
            request_id: request_id,
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
        msg.version
      ]

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    alias IbEx.Client.Messages.MarketData.MarketDataType

    def inspect(msg, _opts) do
      """
      --> MarketData.RequestMarketDataType{
        request_id: #{msg.request_id},
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

    def lookup(_, _) do
      {:error, :lookup_not_necessary}
    end
  end
end
