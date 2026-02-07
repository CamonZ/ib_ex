defmodule IbEx.Client.Types.Order.Condition.Margin do
  @moduledoc """
  Margin condition for an order.

  Activates the order based on the account's margin cushion percentage.
  The `is_more` field indicates whether the trigger fires when the margin
  is above (`true`) or below (`false`) the specified percent.

  Fields:

    * `percent` - The margin cushion percentage threshold
    * `is_more` - If `true`, triggers when margin is above; if `false`, when below
    * `conjunction` - How this condition combines with others (`:and` or `:or`)
  """

  @behaviour IbEx.Client.Types.Order.OrderCondition

  defstruct percent: nil,
            is_more: nil,
            conjunction: :and

  @type t :: %__MODULE__{
          percent: Decimal.t() | nil,
          is_more: boolean() | nil,
          conjunction: :and | :or
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

  @impl true
  def type, do: :margin

  @impl true
  def to_proto(%__MODULE__{} = _condition) do
    raise "not implemented"
  end

  @impl true
  def from_proto(_proto) do
    raise "not implemented"
  end
end
