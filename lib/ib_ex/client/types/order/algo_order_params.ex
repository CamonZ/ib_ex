defmodule IbEx.Client.Types.Order.AlgoOrderParams do
  @moduledoc """
  Params for an algo order
  """
  alias IbEx.Client.Types.Order.AlgoOrderParam

  defstruct algo_id: nil,
            algo_strategy: nil,
            algo_params: []

  @type t :: %__MODULE__{
          algo_id: binary(),
          algo_strategy: binary(),
          algo_params: list(AlgoOrderParam)
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
  def serialize(%__MODULE__{algo_strategy: strategy} = params) when strategy not in ["", nil] do
    [
      params.algo_strategy,
      length(params.algo_params)
    ] ++
      serialize_algo_params(params.algo_params)
  end

  def serialize(%__MODULE__{}), do: []

  @spec serialize_algo_params(list(AlgoOrderParam.t())) :: list()
  defp serialize_algo_params(params) when is_list(params) do
    params
    |> Enum.reduce([], fn %{tag: tag, value: value}, acc -> [tag, value | acc] end)
    |> Enum.reverse()
  end

  defp serialize_algo_params(_), do: []
end

defmodule IbEx.Client.Types.Order.AlgoOrderParam do
  defstruct tag: nil, value: nil

  @type t :: %__MODULE__{
          tag: binary(),
          value: binary()
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
