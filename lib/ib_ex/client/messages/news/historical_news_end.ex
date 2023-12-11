defmodule IbEx.Client.Messages.News.HistoricalNewsEnd do
  @moduledoc """
  Received message to indicate the end of the stream of messages as response to
  a historical news request 
  """

  defstruct request_id: nil, has_more: nil

  @type t :: %__MODULE__{
          request_id: binary(),
          has_more: boolean()
        }

  alias IbEx.Client.Utils

  @spec from_fields(list(binary())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([request_id, has_more]) do
    {:ok, %__MODULE__{request_id: request_id, has_more: Utils.to_bool(has_more)}}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- %News.HistoricalNewsEnd{request_id: #{msg.request_id}, has_more: #{msg.has_more}}"
    end
  end
end
