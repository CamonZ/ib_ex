defmodule IbEx.Client.Types.Order.PegToStockOrVolumeOrderParams do
  defstruct lower_range: nil, upper_range: nil

  @type t :: %__MODULE__{
          lower_range: binary(),
          upper_range: binary()
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(lower, upper) do
    %__MODULE__{
      lower_range: lower,
      upper_range: upper
    }
  end
end
