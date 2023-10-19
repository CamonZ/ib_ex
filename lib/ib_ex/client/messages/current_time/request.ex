defmodule IbEx.Client.Messages.CurrentTime.Request do
  defstruct id: nil, version: nil

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          version: non_neg_integer()
        }

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests

  @message_version 1

  @spec new :: {:ok, __MODULE__.t()} | {:error, :message_not_implemented}
  def new do
    case Requests.message_id_for(__MODULE__) do
      {:ok, message_id} ->
        {:ok, %__MODULE__{id: message_id, version: @message_version}}

      _ ->
        {:error, :message_not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      fields =
        [
          msg.id,
          msg.version
        ]

      Base.build(fields)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      --> %CurrentTime{message_id: #{msg.id} message_version: #{msg.version}}
      """
    end
  end
end
