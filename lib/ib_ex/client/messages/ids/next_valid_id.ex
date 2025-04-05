defmodule IbEx.Client.Messages.Ids.NextValidId do
  @moduledoc """
  Gets the next valid id to be used for order placement
  """
  require Logger
  alias IbEx.Client.Protocols.Traceable

  defstruct version: nil, next_valid_id: nil

  def from_fields([version_str, id_str]) do
    with {version, _} <- Integer.parse(version_str),
         {id, _} <- Integer.parse(id_str) do
      {:ok, %__MODULE__{version: version, next_valid_id: id}}
    else
      _ ->
        {:error, :unexpected_error}
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %NextValidId{version: #{msg.version}, next_valid_id: #{msg.next_valid_id}}"
    end
  end
end
