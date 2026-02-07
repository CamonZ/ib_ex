defmodule IbEx.Client.Messages.News.CancelBulletins do
  @moduledoc """
  Request to cancel the subscription to get news bulletins
  """

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

  defstruct message_id: nil

  @type t :: %__MODULE__{
          message_id: non_neg_integer()
        }

  @spec new() :: {:ok, t()} | {:error, :not_implemented}
  def new do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} -> {:ok, %__MODULE__{message_id: id}}
      :error -> {:error, :not_implemented}
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(_msg) do
      "--> News.CancelBulletins{}"
    end
  end
end
