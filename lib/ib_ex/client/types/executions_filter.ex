defmodule IbEx.Client.Types.ExecutionsFilter do
  @moduledoc """
  Represents the filter used on the executions request message.

  It's used to filter out executions by the following parameters:
  * Client Id
  * Account Code
  * Time
  * Symbol
  * Security Type
  * Exchange
  * Side
  """

  @type t :: %__MODULE__{
          client_id: String.t() | nil,
          account_id: String.t() | nil,
          time: String.t() | nil,
          symbol: String.t() | nil,
          security_type: String.t() | nil,
          exchange: String.t() | nil,
          side: String.t() | nil
        }

  defstruct client_id: nil, account_id: nil, time: nil, symbol: nil, security_type: nil, exchange: nil, side: nil

  @spec new(Keyword.t()) :: {:ok, t} | {:error, :invalid_args}
  def new(opts) when is_list(opts) do
    {
      :ok,
      %__MODULE__{
        client_id: Keyword.get(opts, :client_id),
        account_id: Keyword.get(opts, :account_id),
        time: Keyword.get(opts, :time),
        symbol: Keyword.get(opts, :symbol),
        security_type: Keyword.get(opts, :security_type),
        exchange: Keyword.get(opts, :exchange),
        side: Keyword.get(opts, :side)
      }
    }
  end

  def new(_) do
    {:error, :invalid_args}
  end
end
