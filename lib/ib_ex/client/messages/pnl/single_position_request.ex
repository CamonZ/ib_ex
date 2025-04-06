defmodule IbEx.Client.Messages.Pnl.SinglePositionRequest do
  @moduledoc """
  Message used to request the PnL of a single position on a given trading day.

  The input parameters to create this message are:

  request_id: unique identifier for the request
  account: account associated with the position
  conid: Unique identifier of the instrument
  model_code: (undetermined)
  """

  alias IbEx.Client.Messages.Pnl.AllPositionsRequest
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

  defstruct message_id: nil, request_id: nil, account: nil, model_code: "", conid: nil

  @type t :: %__MODULE__{
          message_id: integer(),
          request_id: non_neg_integer(),
          account: String.t(),
          model_code: String.t(),
          conid: String.t()
        }

  @spec new(non_neg_integer(), String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, :not_implemented}
  def new(request_id, account, conid, model_code \\ "") do
    with {:ok, base_msg} <- AllPositionsRequest.new(request_id, account, model_code),
         {:ok, message_id} <- Requests.message_id_for(__MODULE__) do
      msg = struct(__MODULE__, Map.from_struct(base_msg))
      {:ok, %{msg | message_id: message_id, conid: conid}}
    else
      _ ->
        {:error, :invalid_args}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.request_id, msg.account, msg.model_code, msg.conid])
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      --> Pnl.SinglePositionRequest{
        message_id: #{msg.message_id},
        request_id: #{msg.request_id},
        account: #{msg.account},
        model_code: #{msg.model_code},
        conid: #{msg.conid}
      }
      """
    end
  end
end
