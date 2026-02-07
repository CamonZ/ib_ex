defmodule IbEx.Client.Types.PriceIncrement do
  @moduledoc """
  Represents a price increment rule for a given price range.
  """

  defstruct low_edge: nil,
            increment: nil

  @type t :: %__MODULE__{
          low_edge: float() | nil,
          increment: float() | nil
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
