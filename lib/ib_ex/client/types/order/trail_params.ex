defmodule IbEx.Client.Types.Order.TrailParams do
  defstruct stop_price: nil, percent: nil

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(price, percent) do
    %__MODULE__{
      stop_price: price,
      percent: percent
    }
  end
end
