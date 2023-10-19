defmodule IbEx.Client.Types.Order.ShortSaleParams do
  defstruct short_sale_slot: nil, designated_location: nil, exempt_code: nil

  @type t :: %__MODULE__{
          short_sale_slot: binary(),
          designated_location: binary(),
          exempt_code: binary()
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
      short_sale_slot: slot,
      designated_location: location,
      exempt_code: code
    }
  end
end
