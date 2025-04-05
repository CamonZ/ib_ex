defmodule IbEx.Client.Messages.Executions.ExecutionDataEnd do
  @moduledoc """
  Message received to mark the end of the executions stream for a given request id
  """

  defstruct version: nil, request_id: nil

  @type t :: %__MODULE__{version: non_neg_integer(), request_id: binary()}

  alias IbEx.Client.Utils
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([version_str, request_id]) do
    version = Utils.to_integer(version_str)
    {:ok, %__MODULE__{version: version, request_id: request_id}}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- ExecutionDataEnd{version: #{msg.version}, request_id: #{msg.request_id}}
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
