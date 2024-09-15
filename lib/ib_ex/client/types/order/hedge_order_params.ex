defmodule IbEx.Client.Types.Order.HedgeOrderParams do
  @moduledoc """
  Params for a hedge order
  """
  import IbEx.Client.Utils, only: [list_to_union_type: 1]

  @hedge_types %{
    D: "delta",
    B: "beta",
    F: "FX",
    P: "pair"
  }

  # TODO: what's this?
  @hedge_params %{
    B: "beta=X",
    P: "ratio=Y"
  }

  @type hedge_type :: unquote(list_to_union_type(Map.keys(@hedge_types)))

  def hedge_types, do: @hedge_types
  def hedge_params, do: @hedge_params

  @spec get_param_per_type(hedge_type()) :: binary() | nil
  def get_param_per_type(hedge_type) do
    Map.get(hedge_params(), hedge_type)
  end

  defstruct hedge_type: nil,
            hedge_param: nil

  @type t :: %__MODULE__{
          hedge_type: hedge_type(),
          hedge_param: binary()
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
      params.hedge_type
    ] ++
      serialize_hedge_param(params)
  end

  @spec serialize_hedge_param(__MODULE__.t()) :: list()
  defp serialize_hedge_param(%__MODULE__{hedge_type: type} = params) when type not in ["", nil] do
    [params.hedge_param]
  end

  defp serialize_hedge_param(_), do: []
end
