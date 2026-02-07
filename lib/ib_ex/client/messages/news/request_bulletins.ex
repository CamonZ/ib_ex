defmodule IbEx.Client.Messages.News.RequestBulletins do
  @moduledoc """
  Request to subscribe to news bulletins messages

  Params:

  all_messages:
    When set to true it returns all existing bulletins for the
    current day, if set to false it'll only receive messages for
    new bulletins.
  """

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

  defstruct message_id: nil, all_messages: nil

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          all_messages: boolean()
        }

  @spec new(boolean()) :: {:ok, t()} | {:error, :not_implemented}
  def new(all_messages \\ false) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id, all_messages: all_messages}}

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "--> News.RequestBulletins{all_messages: #{msg.all_messages}}"
    end
  end
end
