defmodule IbEx.Client.Types.Order.TrailParams do
  @moduledoc """
  Params for a trail stop order
  """

  defstruct stop_price: nil, percent: nil

  @type t :: %__MODULE__{
          stop_price: float(),
          percent: Decimal.t()
        }

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

  def serialize(%__MODULE__{} = params) do
    [
      params.stop_price,
      params.percent
    ]
  end
end
