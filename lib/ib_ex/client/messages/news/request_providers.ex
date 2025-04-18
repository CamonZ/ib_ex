defmodule IbEx.Client.Messages.News.RequestProviders do
  @moduledoc """
  Requests the available news providers
  """

  defstruct message_id: nil

  @type t :: %__MODULE__{message_id: non_neg_integer()}

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

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
      Base.build([msg.message_id])
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(_msg) do
      "--> News.RequestProviders{}"
    end
  end
end
