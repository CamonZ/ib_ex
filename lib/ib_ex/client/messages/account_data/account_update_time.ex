defmodule IbEx.Client.Messages.AccountData.AccountUpdateTime do
  @moduledoc """
  Incoming message indicating the update time of an account.
  Assumes no timezone information for the time provided.
  """

  defstruct timestamp: nil

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- AccountUpdateTime{timestamp: #{msg.timestamp}}"
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Messages.AccountData.AccountUpdateTime
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(_msg, table_ref) do
      Subscriptions.lookup(table_ref, AccountUpdateTime)
    end
  end
end
