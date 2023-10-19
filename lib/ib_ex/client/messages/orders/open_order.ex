defmodule IbEx.Client.Messages.Orders.OpenOrder do
  defstruct version: 155,
            order: nil

  require Logger
  alias IbEx.Client.Messages.Orders.Decoder

  def from_fields(fields) when is_list(fields) do
    {:ok, %__MODULE__{order: Decoder.parse(fields)}}
  end

  def from_fields(fields) do
    {:error, {:invalid_args, fields}}
  end
end
