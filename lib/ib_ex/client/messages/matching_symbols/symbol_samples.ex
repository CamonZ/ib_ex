defmodule IbEx.Client.Messages.MatchingSymbols.SymbolSamples do
  @moduledoc """
  Response message from requesting a list of matching symbols

  Within the contract descriptions is the list of contracts that match the specified
  pattern.


  """

  defstruct request_id: nil, contracts: []

  alias IbEx.Client.Types.ContractDescription

  require Logger

  def from_fields([request_id, _descriptions_length | rest] = fields) do
    case parse_descriptions(rest, []) do
      {:ok, descriptions} ->
        {:ok,
         %__MODULE__{
           request_id: request_id,
           contracts: descriptions
         }}

      {:error, :invalid_args} ->
        Logger.error("Fields: #{inspect(fields, limit: :infinity)}")
        {:error, :invalid_args}
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defp parse_descriptions([], accum) do
    {:ok, Enum.reverse(accum)}
  end

  defp parse_descriptions(fields, accum) do
    with {contract_fields, rest} <- extract_contract_fields(fields),
         {:ok, description} <- ContractDescription.from_fields(contract_fields) do
      parse_descriptions(rest, [description] ++ accum)
    end
  rescue
    ArgumentError ->
      {:error, :invalid_args}
  end

  @base_fields_length 8
  @derivatives_length_position 5

  defp extract_contract_fields(fields) do
    derivatives_length = String.to_integer(Enum.at(fields, @derivatives_length_position))
    Enum.split(fields, @base_fields_length + derivatives_length)
  end
end
