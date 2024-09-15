defmodule IbEx.Client.Types.Order.SoftDollarTierParams do
  @moduledoc """
  Params for soft dollar tier 
  """

  defstruct name: nil,
            value: nil,
            display_name: nil

  @type t :: %__MODULE__{
          name: binary(),
          value: Decimal.t(),
          display_name: binary()
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

  @spec serialize(__MODULE__.t()) :: list()
  def serialize(%__MODULE__{} = params) do
    [params.name, params.value]
  end
end
