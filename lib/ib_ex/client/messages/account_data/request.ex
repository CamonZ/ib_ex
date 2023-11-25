defmodule IbEx.Client.Messages.AccountData.Request do
  @message_version 1

  alias IbEx.Client.Messages.Base
  alias IbEx.Client.Messages.Requests

  defstruct message_id: nil, version: @message_version, subscribe: nil, account_code: nil

  @type t :: %__MODULE__{
    message_id: non_neg_integer(),
    version: non_neg_integer(),
    subscribe: boolean(),
    account_code: binary() | nil
  }

  @spec new(boolean(), binary() | nil) :: {:ok, t()} | {:error, :not_implemented}
  def new(subscribe, account_code \\ nil) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {
          :ok,
          %__MODULE__{
            message_id: id,
            subscribe: subscribe,
            account_code: account_code
          }
        }

      :error ->
        {:error, :not_implemented}
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([msg.message_id, msg.version, msg.subscribe, msg.account_code])
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "--> AccountUpdates{message_id: #{msg.message_id}, subscribe: #{msg.subscribe}, account_code: #{inspect(msg.account_code)}}"
    end
  end
end
