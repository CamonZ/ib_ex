defmodule IbEx.Client.Messages.News.CancelBulletins do
  @moduledoc """
  Request to cancel the subscription to get news bulletins
  """

  @message_version 1

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

  defstruct message_id: nil, version: @message_version

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          version: non_neg_integer()
        }

  @spec new() :: {:ok, t()} | {:error, :not_implemented}
  def new do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} -> {:ok, %__MODULE__{message_id: id}}
      :error -> {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.version])
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(_msg) do
      "--> News.CancelBulletins{}"
    end
  end
end
