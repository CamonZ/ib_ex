defmodule IbEx.Client.Types.Order.Condition.Time do
  @moduledoc """
  Time condition for an order.

  Activates the order based on a time threshold. The `is_more` field
  indicates whether the trigger fires after (`true`) or before (`false`)
  the specified time.

  Fields:

    * `time` - The time threshold (formatted as yyyyMMdd HH:mm:ss timezone)
    * `is_more` - If `true`, triggers after the time; if `false`, before
    * `conjunction` - How this condition combines with others (`:and` or `:or`)
  """

  @behaviour IbEx.Client.Types.Order.OrderCondition

  defstruct time: nil,
            is_more: nil,
            conjunction: :and

  @type t :: %__MODULE__{
          time: binary() | nil,
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
  def type, do: :time

  @impl true
  def to_proto(%__MODULE__{} = _condition) do
    raise "not implemented"
  end

  @impl true
  def from_proto(_proto) do
    raise "not implemented"
  end
end
