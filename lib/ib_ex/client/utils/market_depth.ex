defmodule IbEx.Client.Utils.MarketDepth do
  @moduledoc """
  Utils for parsing incoming messages for L2 data
  """

  def parse_operation(str) do
    case str do
      "0" -> {:ok, "insert"}
      "1" -> {:ok, "update"}
      "2" -> {:ok, "delete"}
      _ -> {:error, :invalid_args}
    end
  end

  def parse_side(str) do
    case str do
      "0" -> {:ok, "ask"}
      "1" -> {:ok, "bid"}
      _ -> {:error, :invalid_args}
    end
  end
end
