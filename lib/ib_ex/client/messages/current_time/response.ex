defmodule IbEx.Client.Messages.CurrentTime.Response do
  @moduledoc """
  Message response with the current TWS client time.
  """
  defstruct version: nil, timestamp: nil

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

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

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %CurrentTime{version: #{msg.version}, timestamp: #{msg.timestamp}}
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Messages.CurrentTime.Response
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(_msg, table_ref) do
      Subscriptions.lookup(table_ref, Response)
    end
  end
end
