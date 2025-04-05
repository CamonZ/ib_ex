defmodule IbEx.Client.Messages.InitConnection.Response do
  @moduledoc """
  The response to the InitConnection message, on the original API it's referred to as the ConnectionAck
  """

  defstruct server_version: nil, connection_timestamp: nil

  alias IbEx.Client.Utils
  alias IbEx.Client.Protocols.Traceable

  def from_fields([server_version, timestamp_str]) do
    with {version, _} <- Integer.parse(server_version),
         {:ok, ts} <- Utils.parse_init_connection_timestamp(timestamp_str) do
      {:ok,
       %__MODULE__{
         server_version: version,
         connection_timestamp: ts
       }}
    else
      _ ->
        {:error, :unexpected_error}
    end
  rescue
    _ ->
      {:error, :unexpected_error}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %InitConnection{version: #{msg.server_version} timestamp: #{msg.connection_timestamp}}"
    end
  end
end
