defmodule IbEx.Client.Messages.News.RequestBulletins do
  @moduledoc """
  Request to subscribe to news bulletins messages

  Params:

  all_messages:
    When set to true it returns all existing bulletins for the
    current day, if set to false it'll only receive messages for
    new bulletins.
  """

  @message_version 1

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests

  defstruct message_id: nil, version: @message_version, all_messages: nil

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          version: non_neg_integer(),
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

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.version, msg.all_messages])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> News.RequestBulletins{all_messages: #{msg.all_messages}}"
    end
  end
end
