defmodule IbEx.Client.Messages.AccountData.AccountDownloadEnd do
  @moduledoc """
  Incoming message indicating the end of the batch of account detail messages
  """

  defstruct version: nil, account: nil

  alias IbEx.Client.Protocols.Subscribable

  def from_fields([version_str, account]) do
    case Integer.parse(version_str) do
      {version, _} ->
        {
          :ok,
          %__MODULE__{
            version: version,
            account: account
          }
        }

      _ ->
        {:error, :invalid_args}
    end
  end

  def from_fields(_fields) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- AccountDownloadEnd{account: #{msg.account}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Messages.AccountData.AccountDownloadEnd
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(_msg, table_ref) do
      Subscriptions.lookup(table_ref, AccountDownloadEnd)
    end
  end
end
