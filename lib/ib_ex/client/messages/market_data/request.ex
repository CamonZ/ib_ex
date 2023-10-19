defmodule IbEx.Client.Messages.MarketData.Request do
  @message_version 11

  defstruct contract: nil, message_id: nil, version: nil

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests

  def new(_contract) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {:ok, %__MODULE__{message_id: id, version: @message_version}}

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.version])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> MarketData{version: #{msg.version}}"
    end
  end
end
