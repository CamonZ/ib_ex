defmodule IbEx.Client.Types.Order.Condition.Execution do
  @moduledoc """
  Execution condition for an order.

  Activates the order when a trade execution occurs on the specified
  instrument. Unlike other conditions, execution conditions do not have
  an `is_more` field since they trigger on the occurrence of any execution.

  Fields:

    * `sec_type` - The security type of the instrument (e.g., "STK", "OPT")
    * `exchange` - The exchange where the execution is monitored
    * `symbol` - The symbol of the instrument to monitor
    * `conjunction` - How this condition combines with others (`:and` or `:or`)
  """

  @behaviour IbEx.Client.Types.Order.OrderCondition

  defstruct sec_type: nil,
            exchange: nil,
            symbol: nil,
            conjunction: :and

  @type t :: %__MODULE__{
          sec_type: binary() | nil,
          exchange: binary() | nil,
          symbol: binary() | nil,
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
  def type, do: :execution

  @impl true
  def to_proto(%__MODULE__{} = _condition) do
    raise "not implemented"
  end

  @impl true
  def from_proto(_proto) do
    raise "not implemented"
  end
end
