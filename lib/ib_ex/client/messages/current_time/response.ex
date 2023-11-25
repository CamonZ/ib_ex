defmodule IbEx.Client.Messages.CurrentTime.Response do
  @moduledoc """
  Message response with the current TWS client time.
  """
  defstruct version: nil, timestamp: nil

  def from_fields([version_str, epoch_str]) do
    with {version, _} <- Integer.parse(version_str),
         {epoch, _} <- Integer.parse(epoch_str),
         {:ok, timestamp} <- DateTime.from_unix(epoch) do
      {:ok, %__MODULE__{version: version, timestamp: timestamp}}
    else
      _ ->
        {:error, :invalid_args}
    end
  end

  def from_fields(_fields) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %CurrentTime{version: #{msg.version}, timestamp: #{msg.timestamp}}
      """
    end
  end
end
