defmodule IbEx.Client.Types.Order.Condition.PercentChange do
  @moduledoc """
  Percent change condition for an order.

  Activates the order when the percent change of the specified contract
  reaches the given threshold. The `is_more` field indicates whether
  the trigger fires when the change is above (`true`) or below (`false`)
  the target.

  Fields:

    * `con_id` - Contract identifier for the instrument to monitor
    * `exchange` - Exchange where the percent change is checked
    * `change_percent` - The target percent change threshold
    * `is_more` - If `true`, triggers when change is above; if `false`, when below
    * `conjunction` - How this condition combines with others (`:and` or `:or`)
  """

  @behaviour IbEx.Client.Types.Order.OrderCondition

  defstruct con_id: nil,
            exchange: nil,
            change_percent: nil,
            is_more: nil,
            conjunction: :and

  @type t :: %__MODULE__{
          con_id: non_neg_integer() | nil,
          exchange: binary() | nil,
          change_percent: Decimal.t() | nil,
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
  def type, do: :percent_change

  @impl true
  def to_proto(%__MODULE__{} = _condition) do
    raise "not implemented"
  end

  @impl true
  def from_proto(_proto) do
    raise "not implemented"
  end
end
