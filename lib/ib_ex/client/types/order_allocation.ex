defmodule IbEx.Client.Types.OrderAllocation do
  @moduledoc """
  Represents a client allocation for a given order.

  Includes information about the account, position changes, and allocation
  quantities for financial advisor (FA) order allocations.
  """

  defstruct account: nil,
            position: nil,
            position_desired: nil,
            position_after: nil,
            desired_alloc_qty: nil,
            allowed_alloc_qty: nil,
            is_monetary: false

  @type t :: %__MODULE__{
          account: binary() | nil,
          position: Decimal.t() | nil,
          position_desired: Decimal.t() | nil,
          position_after: Decimal.t() | nil,
          desired_alloc_qty: Decimal.t() | nil,
          allowed_alloc_qty: Decimal.t() | nil,
          is_monetary: boolean()
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
