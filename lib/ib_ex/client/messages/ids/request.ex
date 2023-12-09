defmodule IbEx.Client.Messages.Ids.Request do
  @message_version 1

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests

  defstruct message_id: nil, version: @message_version, number_of_ids: 1

  def new do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id}}

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.version, msg.number_of_ids])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> Ids.Request{number_of_ids: #{msg.number_of_ids}}"
    end
  end
end
