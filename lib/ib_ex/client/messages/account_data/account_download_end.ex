defmodule IbEx.Client.Messages.AccountData.AccountDownloadEnd do
  @moduledoc """
  Incoming message indicating the end of the batch of account detail messages
  """

  defstruct account: nil

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
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
