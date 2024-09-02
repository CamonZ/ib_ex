defmodule IbEx.Client.Types.DeltaNeutralContract do
  defstruct conid: nil, delta: nil, price: nil

  @type t :: %__MODULE__{
          conid: binary(),
          delta: Decimal.t(),
          price: Decimal.t()
        }

  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end

  def new(), do: new(%{})

  def serialize(%__MODULE__{} = contract) do
    [
      contract.conid,
      contract.delta,
      contract.price
    ]
  end
end
