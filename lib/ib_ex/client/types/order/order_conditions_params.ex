defmodule IbEx.Client.Types.Order.OrderConditionsParams do
  @moduledoc """
  Serializes list of OrderCondition structs for Order serialization. 
  """
  alias IbEx.Client.Types.Order.OrderCondition

  defstruct conditions: [], conditions_cancel_order: false, conditions_ignore_rth: false

  @type t :: %__MODULE__{
          conditions: list(OrderCondition.t()),
          conditions_cancel_order: boolean(),
          conditions_ignore_rth: boolean()
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
  def serialize(%__MODULE__{conditions: []}), do: [0]

  def serialize(%__MODULE__{} = params) do
    [length(params.conditions)] ++
      serialize_conditions(params.conditions) ++
      [params.conditions_ignore_rth, params.conditions_cancel_order]
  end

  @spec serialize_conditions(list(OrderCondition.t())) :: list()
  defp serialize_conditions(params) when is_list(params) do
    params
    |> Enum.reduce([], fn cond, acc -> [OrderCondition.serialize(cond) | acc] end)
    |> Enum.reverse()
    |> List.flatten()
  end

  defp serialize_conditions(_), do: []
end

defmodule IbEx.Client.Types.Order.OrderCondition do
  @moduledoc """
  Behaviour for order condition types.

  Defines the contract that all condition types must implement.
  Condition types determine when an order should be activated based on
  price, time, margin, execution, volume, or percent change criteria.

  Each condition also carries a `conjunction` field (`:and` or `:or`)
  that defines how it combines with other conditions in a list.

  ## Condition Types

    * `:price` - Activates based on a contract's price
    * `:time` - Activates based on time
    * `:margin` - Activates based on margin cushion percentage
    * `:execution` - Activates when an execution on a specified instrument occurs
    * `:volume` - Activates based on a contract's volume
    * `:percent_change` - Activates based on a contract's percent change
  """

  import IbEx.Client.Utils, only: [list_to_union_type: 1]

  @condition_types ~w(price time margin execution volume percent_change)a
  @type condition_type :: unquote(list_to_union_type(@condition_types))

  @type conjunction :: :and | :or

  @type t ::
          IbEx.Client.Types.Order.Condition.Price.t()
          | IbEx.Client.Types.Order.Condition.Time.t()
          | IbEx.Client.Types.Order.Condition.Margin.t()
          | IbEx.Client.Types.Order.Condition.Execution.t()
          | IbEx.Client.Types.Order.Condition.Volume.t()
          | IbEx.Client.Types.Order.Condition.PercentChange.t()

  @doc "Returns the condition type atom"
  @callback type() :: condition_type()

  @doc "Converts the condition struct into a protocol buffer representation"
  @callback to_proto(struct()) :: map()

  @doc "Builds a condition struct from a protocol buffer representation"
  @callback from_proto(map()) :: struct()

  @doc "Returns the list of valid condition type atoms"
  def condition_types, do: @condition_types

  # TODO: implement
  @spec serialize(t()) :: list()
  def serialize(%{__struct__: _module}) do
    []
  end
end
