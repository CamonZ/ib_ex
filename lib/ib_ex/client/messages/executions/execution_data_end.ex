defmodule IbEx.Client.Messages.Executions.ExecutionDataEnd do
  @moduledoc """
  Message received to mark the end of the executions stream for a given request id
  """

  defstruct request_id: nil

  @type t :: %__MODULE__{request_id: binary()}

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- ExecutionDataEnd{request_id: #{msg.request_id}}
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
