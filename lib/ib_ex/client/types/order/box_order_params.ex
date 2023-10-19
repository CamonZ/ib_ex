defmodule IbEx.Client.Types.Order.BoxOrderParams do
  defstruct starting_price: nil, stock_reference_price: nil, delta: nil

  @type t :: %__MODULE__{
          starting_price: binary(),
          stock_reference_price: binary(),
          delta: binary()
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(starting_price, reference_price, delta) do
    %__MODULE__{
      starting_price: starting_price,
      stock_reference_price: reference_price,
      delta: delta
    }
  end
end
