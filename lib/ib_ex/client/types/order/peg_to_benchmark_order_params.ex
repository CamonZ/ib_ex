defmodule IbEx.Client.Types.Order.PegToBenchmarkOrderParams do
  @moduledoc """
  Represents Pegged To Benchmark order parameters
  """
  defstruct reference_contract_id: 0,
            is_pegged_change_amount_decrease: false,
            pegged_change_amount: Decimal.new("0.0"),
            reference_change_amoung: Decimal.new("0.0"),
            reference_exchange_id: nil

  @type t :: %__MODULE__{
          reference_contract_id: integer(),
          is_pegged_change_amount_decrease: boolean(),
          pegged_change_amount: Decimal.t(),
          reference_change_amoung: Decimal.t(),
          reference_exchange_id: binary()
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(), do: new(%{})

  @spec serialize(__MODULE__.t(), boolean()) :: list()
  def serialize(%__MODULE__{} = params, true) do
    [
      params.reference_contract_id,
      params.is_pegged_change_amount_decrease,
      params.pegged_change_amount,
      params.reference_change_amoung,
      params.reference_exchange_id
    ]
  end

  def serialize(_, _), do: []
end
