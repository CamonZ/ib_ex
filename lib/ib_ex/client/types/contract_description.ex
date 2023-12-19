defmodule IbEx.Client.Types.ContractDescription do
  @moduledoc """
  Defines a contract description as returned by the SymbolSamples
  response message
  """

  defstruct contract: nil,
            derivative_security_types: []

  alias IbEx.Client.Types.Contract

  @type t :: %__MODULE__{
          contract: Contract.t(),
          derivative_security_types: list(binary())
        }

  @extra_fields_size 2

  @spec from_symbol_samples(list()) :: {:ok, t()} | {:error, :invalid_args}
  def from_symbol_samples([con_id, symbol, sec_type, exchange, currency, _ | rest]) do
    derivatives_length = length(rest) - @extra_fields_size

    {derivatives, [description, issuer_id]} = Enum.split(rest, derivatives_length)

    args = %{
      conid: con_id,
      symbol: symbol,
      security_type: sec_type,
      primary_exchange: exchange,
      currency: currency,
      description: description,
      issuer_id: issuer_id
    }

    new(%{contract_args: args, derivative_types: derivatives})
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def from_symbol_samples(_) do
    {:error, :invalid_args}
  end

  @spec new(map()) :: {:ok, t()} | {:error, :invalid_args}
  def new(%{contract_args: args, derivative_types: derivatives}) do
    {:ok, %__MODULE__{contract: Contract.new(args), derivative_security_types: derivatives}}
  end

  def new(_) do
    {:error, :invalid_args}
  end
end
