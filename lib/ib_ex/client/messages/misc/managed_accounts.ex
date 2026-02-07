defmodule IbEx.Client.Messages.Misc.ManagedAccounts do
  require Logger

  alias IbEx.Client.Protocols.Traceable

  defstruct accounts: nil

  def from_protobuf(payload) when is_binary(payload) do
    proto = IbEx.Client.Proto.Protobuf.ManagedAccounts.decode(payload)

    {:ok, %__MODULE__{accounts: proto.accounts_list}}
  rescue
    err ->
      Logger.warning("Error decoding ManagedAccounts protobuf: #{inspect(err)}")
      {:error, :decode_error}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %ManagedAccounts{accounts: #{msg.accounts}}"
    end
  end
end
