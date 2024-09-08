defmodule IbEx.Client.Types.Order.ShortSaleParams do
  @moduledoc """
  Represents the short sale params of an order

  the fields in the struct are:

  * slot: Short Sale Slot. 0 for retail, 1 or 2 for institutions
  * location: Designated Location. populated when slot = 2
  * code: Exempt Code
  """

  defstruct short_sale_slot: 0, designated_location: nil, exempt_code: -1

  # 0 for retail, 1 or 2 for institutions
  # 1 if you hold the shares, 2 if they will be delivered from elsewhere.  
  # Only for Action=SSHORT
  @type short_sale_slot :: 0..2

  @type t :: %__MODULE__{
          short_sale_slot: short_sale_slot(),
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

  def new(), do: new(%{})

  def new(slot, location, code) do
    %__MODULE__{
      short_sale_slot: slot,
      designated_location: location,
      exempt_code: code
    }
  end

  def serialize(%__MODULE__{} = params) do
    [
      params.short_sale_slot,
      params.designated_location,
      params.exempt_code
    ]
  end
end
