defmodule IbEx.Client.Messages.Executions.ExecutionData do
  @moduledoc """
  Message received as a response of the Executions request message
  """

  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.Execution
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defstruct request_id: nil, contract: nil, execution: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          contract: Contract.t(),
          execution: Execution.t()
        }

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- ExecutionData{
        request_id: #{msg.request_id},
        contract: #{inspect(msg.contract)},
        execution: #{inspect(msg.execution)}
      }
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions
    alias IbEx.Client.Messages.Executions.ExecutionData

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    # we subscribe on lookup for the commission report attached to this execution
    def lookup(%ExecutionData{} = msg, table_ref) do
      case Subscriptions.lookup(table_ref, msg.request_id) do
        {:ok, pid} ->
          Subscriptions.subscribe_by_custom_id(table_ref, msg.execution.execution_id, pid)
          {:ok, pid}

        error ->
          error
      end
    end
  end
end
