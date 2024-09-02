defmodule IbEx.Client.Types.Order.ScaleOrderParams do
  @moduledoc """
  Params for a scale order
  """

  defstruct init_level_size: nil,
            subs_level_size: nil,
            price_increment: nil,
            price_adjust_value: nil,
            price_adjust_interval: nil,
            profit_offset: nil,
            auto_reset: nil,
            init_position: nil,
            init_fill_quantity: nil,
            random_percent: nil,
            table: nil,

            # for GTC orders
            active_start_time: nil,
            active_stop_time: nil

  @type t :: %__MODULE__{
          init_level_size: non_neg_integer(),
          subs_level_size: non_neg_integer(),
          price_increment: Decimal.t(),
          price_adjust_value: Decimal.t(),
          price_adjust_interval: non_neg_integer(),
          profit_offset: Decimal.t(),
          auto_reset: boolean(),
          init_position: non_neg_integer(),
          init_fill_quantity: non_neg_integer(),
          random_percent: boolean(),
          table: binary(),
          active_start_time: binary(),
          active_stop_time: binary()
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
      params.init_level_size,
      params.subs_level_size
    ] ++
      serialize_scale_price_increment_params(params) ++
      [
        params.table,
        params.active_start_time,
        params.active_stop_time
      ]
  end

  @spec serialize_scale_price_increment_params(__MODULE__.t()) :: list()
  defp serialize_scale_price_increment_params(%__MODULE__{price_increment: nil}), do: []
  defp serialize_scale_price_increment_params(%__MODULE__{price_increment: incr} = params) do
    case Decimal.gt?(incr, 0) do
      true ->
        [
          params.price_adjust_value,
          params.profit_offset,
          params.auto_reset,
          params.init_position,
          params.init_fill_quantity,
          params.random_percent
        ]

      false ->
        []
    end
  end

  defp serialize_scale_price_increment_params(_), do: []
end
