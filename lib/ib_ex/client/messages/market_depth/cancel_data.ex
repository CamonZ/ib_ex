defmodule IbEx.Client.Messages.MarketDepth.CancelData do
  @moduledoc """
  Requests to cancel the subscription to L2 Market Data updates

  The input parameters are:

  * Request id
  * Is Smart Depth
  """

  @version 1

  defstruct message_id: nil,
            version: @version,
            request_id: "",
            smart_depth?: true

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          version: non_neg_integer(),
          request_id: String.t(),
          smart_depth?: boolean()
        }

  alias IbEx.Client.Messages.Requests

  @spec new(String.t(), boolean()) :: {:ok, t()} | {:error, :not_implemented}
  def new(request_id, is_smart_depth \\ true) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {
          :ok,
          %__MODULE__{
            message_id: id,
            request_id: request_id,
            smart_depth?: is_smart_depth
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
        msg.request_id,
        msg.smart_depth?
      ]

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      --> %MarketDepth.CancelData{
        request_id: #{msg.request_id},
        smart_depth?: #{msg.smart_depth?}
      }
      """
    end
  end
end
