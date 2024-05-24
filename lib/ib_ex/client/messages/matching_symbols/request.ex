defmodule IbEx.Client.Messages.MatchingSymbols.Request do
  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests

  defstruct pattern: nil, request_id: nil, message_id: nil

  def new(opts \\ []) do
    with {:ok, id} <- Requests.message_id_for(__MODULE__),
         {:ok, request_id} <- Keyword.fetch(opts, :request_id),
         {:ok, pattern} <- Keyword.fetch(opts, :pattern) do
      {:ok, %__MODULE__{message_id: id, request_id: request_id, pattern: pattern}}
    else
      _ ->
        {:error, :invalid_args}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.request_id, msg.pattern])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> MatchingSymbols{id: #{msg.message_id}, request_id: #{msg.request_id}, pattern: #{msg.pattern}}"
    end
  end
end
