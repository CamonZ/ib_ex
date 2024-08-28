defmodule IbEx.Client.Types.Order.AlgoOrderParams do
  @moduledoc """
  Params for an algo order
  """
  alias IbEx.Client.Types.TagValueList

  defstruct algo_strategy: nil,
            algo_params: [],
            algo_id: nil

  @type t :: %__MODULE__{
          algo_strategy: binary(),
          algo_params: TagValueList.t(),
          algo_id: binary()
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
  def serialize(%__MODULE__{} = params) do
    [
      params.algo_strategy
    ] ++
      serialize_algo_params(params) ++
      [params.algo_id]
  end

  @spec serialize_algo_params(__MODULE__.t()) :: list()
  defp serialize_algo_params(%__MODULE__{algo_strategy: strategy} = params) when strategy not in ["", nil] do
    [length(params.algo_params)] ++
      TagValueList.serialize(params.algo_params)
  end

  defp serialize_algo_params(_), do: []
end
