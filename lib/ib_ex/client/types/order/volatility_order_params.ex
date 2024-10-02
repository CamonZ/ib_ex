defmodule IbEx.Client.Types.Order.VolatilityOrderParams do
  defstruct volatility: nil,
            volatility_type: nil

  # 1 = daily, 2 = annual
  @type volatility_type :: 1..2

  @type t :: %__MODULE__{
          volatility: Decimal.t(),
          volatility_type: volatility_type(),
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

  def serialize(%__MODULE__{} = params) do
    [
      params.volatility,
      params.volatility_type,
    ]
  end
end
