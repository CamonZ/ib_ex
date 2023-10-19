defmodule IbEx.Client.Messages.Misc.ManagedAccounts do
  require Logger

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

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- %ManagedAccounts{version: #{msg.version} accounts: #{msg.accounts}}"
    end
  end
end
