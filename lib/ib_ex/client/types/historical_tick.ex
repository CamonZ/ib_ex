defmodule IbEx.Client.Types.HistoricalTick do
  @moduledoc """
  Represents a historical tick with timestamp and price data.

  Used for midpoint historical tick requests.
  """

  defstruct time: nil,
            price: nil,
            size: nil

  @type t :: %__MODULE__{
          time: non_neg_integer() | nil,
          price: float() | nil,
          size: Decimal.t() | nil
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
end
