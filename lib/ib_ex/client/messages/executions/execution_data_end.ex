defmodule IbEx.Client.Messages.Executions.ExecutionDataEnd do
  @moduledoc """
  Message received to mark the end of the executions stream for a given request id
  """

  defstruct version: nil, request_id: nil

  @type t :: %__MODULE__{version: non_neg_integer(), request_id: binary()}

  alias IbEx.Client.Utils

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([version_str, request_id]) do
    version = Utils.to_integer(version_str)
    {:ok, %__MODULE__{version: version, request_id: request_id}}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- ExecutionDataEnd{version: #{msg.version}, request_id: #{msg.request_id}}
      """
    end
  end
end
