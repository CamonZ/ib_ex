defmodule IbEx.Client.Messages.Misc.ManagedAccounts do
  require Logger

  alias IbEx.Client.Protocols.Traceable

  defstruct version: nil, accounts: nil

  def from_fields([version, accounts]) do
    msg = %__MODULE__{
      version: String.to_integer(version),
      accounts: accounts
    }

    {:ok, msg}
  end

  def from_fields(fields) do
    Logger.warning("Trying to parse message as ManagedAccounts: #{inspect(fields)}")
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- %ManagedAccounts{version: #{msg.version} accounts: #{msg.accounts}}"
    end
  end
end
