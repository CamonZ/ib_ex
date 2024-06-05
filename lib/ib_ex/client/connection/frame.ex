defmodule IbEx.Client.Connection.Frame do
  @moduledoc """
    Low level utilities for serializing a binary
    when communicating with the IBKR TWS / Gateway
  """

  @spec pack(binary()) :: binary()
  def pack(str, include_length \\ true) do
    case include_length do
      true -> String.slice(:erlang.term_to_binary(str), 2..-1//1)
      false -> str
    end
  end
end
