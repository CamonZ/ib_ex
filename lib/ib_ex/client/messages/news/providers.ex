defmodule IbEx.Client.Messages.News.Providers do
  @moduledoc """
  Response to the RequestProviders message

  Receives a list of different news providers 
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct items: nil

  def from_fields([_number_of_items | rest]) when length(rest) >= 5 do
    {:ok, %__MODULE__{items: build_items(rest, [])}}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defp build_items([], acc) do
    Enum.reverse(acc)
  end

  defp build_items(fields, acc) when is_list(fields) do
    {[code, name], rest} = Enum.split(fields, 2)
    build_items(rest, [{code, name} | acc])
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %News.Providers{items: #{inspect(msg.items)}}
      """
    end
  end
end
