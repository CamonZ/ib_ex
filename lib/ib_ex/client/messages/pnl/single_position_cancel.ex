defmodule IbEx.Client.Messages.Pnl.SinglePositionCancel do
  @moduledoc """
  Message used to cancel the subscription to PnL updates of a single position on a given trading day.

  The input parameters to create this message are:

  request_id: unique identifier for the request
  """

  alias IbEx.Client.Messages.Requests

  defstruct message_id: nil, request_id: nil

  @type t :: %__MODULE__{message_id: integer(), request_id: non_neg_integer()}

  @spec new(non_neg_integer()) :: {:ok, t()} | {:error, :not_implemented}
  def new(request_id) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} -> {:ok, %__MODULE__{message_id: message_id, request_id: request_id}}
      _ -> {:error, :invalid_arsg}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.request_id])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      --> Pnl.SinglePositionCancel{message_id: #{msg.message_id}, request_id: #{msg.request_id}}
      """
    end
  end
end
