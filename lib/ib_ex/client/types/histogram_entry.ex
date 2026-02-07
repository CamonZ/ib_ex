defmodule IbEx.Client.Types.HistogramEntry do
  @moduledoc """
  Represents a single entry in a price histogram.
  """

  defstruct price: nil,
            size: nil

  @type t :: %__MODULE__{
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
