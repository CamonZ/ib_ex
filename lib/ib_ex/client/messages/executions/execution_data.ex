defmodule IbEx.Client.Messages.Executions.ExecutionData do
  @moduledoc """
  Message received as a response of the Executions request message
  """

  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.Execution
  alias IbEx.Client.Protocols.Subscribable

  defstruct request_id: nil, contract: nil, execution: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          contract: Contract.t(),
          execution: Execution.t()
        }

  @contract_fields_length 11

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([request_id, order_id | rest]) do
    {contract_fields, execution_fields} = Enum.split(rest, @contract_fields_length)

    with {:ok, contract} <- Contract.from_serialized_fields(contract_fields),
         {:ok, execution} <- Execution.from_execution_data([order_id | execution_fields]) do
      {
        :ok,
        %__MODULE__{
          request_id: request_id,
          contract: contract,
          execution: execution
        }
      }
    else
      _ ->
        {:error, :invalid_args}
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
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
