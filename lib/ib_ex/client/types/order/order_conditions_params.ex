defmodule IbEx.Client.Types.Order.OrderConditionsParams do
  @moduledoc """
  Serializes list of OrderCondition structs for Order serialization. 
  """
  alias IbEx.Client.Types.Order.OrderCondition
  import IbEx.Client.Utils, only: [list_to_union_type: 1]

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
  Implements the following OrderCondition types:

    :price
    :time
    :margin
    :execution
    :volume
    :percent_hange

  """
  import IbEx.Client.Utils, only: [list_to_union_type: 1]
  defstruct type: nil

  @condition_types ~w(price time margin execution volume percent_change)a
  @type condition_types :: unquote(list_to_union_type(@condition_types))

  @type t :: %__MODULE__{
          type: condition_types()
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

  # TODO: implement
  @spec serialize(__MODULE__.t()) :: list()
  def serialize(%__MODULE__{type: :price}) do
    []
  end

  def serialize(%__MODULE__{}) do
    []
  end
end
