defmodule IbEx.Client.Messages.MarketDepth.Exchanges do
  @moduledoc """
  Response to the RequestExchanges message

  Receives a list of different exchanges from which to request market depth data
  """

  defstruct descriptions: nil

  alias IbEx.Client.Types.MarketDepthDescription

  def from_fields([_number_of_descriptions | rest]) when length(rest) >= 5 do
    descriptions = build_descriptions(rest, [])

    {:ok, %__MODULE__{descriptions: descriptions}}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defp build_descriptions([], acc) do
    Enum.reverse(acc)
  end

  defp build_descriptions(fields, acc) when is_list(fields) do
    {desc_fields, rest} = Enum.split(fields, 5)

    case MarketDepthDescription.from_market_depth_exchanges(desc_fields) do
      {:ok, description} ->
        build_descriptions(rest, [description | acc])

      _ ->
        build_descriptions(rest, acc)
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %MarketDepth.Exchanges{descriptions: #{inspect(msg.descriptions)}}
      """
    end
  end
end
