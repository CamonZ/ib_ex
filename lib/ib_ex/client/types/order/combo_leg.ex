defmodule IbEx.Client.Types.Order.ComboLeg do
  @moduledoc """
  Represents order combo leg params

  TODO: implement serialization
  """
  defstruct price: nil

  @type t :: %__MODULE__{
          price: Decimal.t()
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
