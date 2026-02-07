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

  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %News.HistoricalNewsEnd{request_id: #{msg.request_id}, has_more: #{msg.has_more}}"
    end
  end
end
