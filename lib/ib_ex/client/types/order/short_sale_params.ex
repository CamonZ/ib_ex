defmodule IbEx.Client.Types.Order.ShortSaleParams do
  @moduledoc """
  Represents the short sale params of an order

  the fields in the struct are:

  * slot: Short Sale Slot
  * location: Designated Location
  * code: Excempt Code
  """

  defstruct slot: nil, location: nil, code: nil

  @type t :: %__MODULE__{
          slot: binary(),
          location: binary(),
          code: binary()
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(slot, location, code) do
    %__MODULE__{
      slot: slot,
      location: location,
      code: code
    }
  end

  def serializable_fields(%__MODULE__{} = params) do
    [
      params.slot,
      params.location,
      params.code
    ]
  end
end
