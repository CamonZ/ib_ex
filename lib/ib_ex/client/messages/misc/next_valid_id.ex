defmodule IbEx.Client.Messages.Misc.NextValidId do
  require Logger

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

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- %NextValidId{version: #{msg.version} next_valid_id: #{msg.next_valid_id}}"
    end
  end
end
