defmodule IbEx.Client.Messages.CurrentTime.Response do
  @moduledoc """
  Message response with the current TWS client time.
  """
  defstruct timestamp: nil

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %CurrentTime{timestamp: #{msg.timestamp}}
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
