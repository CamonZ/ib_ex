defmodule IbEx.Client.Messages.News.Providers do
  @moduledoc """
  Response to the RequestProviders message

  Receives a list of different news providers 
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct items: nil

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %News.Providers{items: #{inspect(msg.items)}}
      """
    end
  end
end
