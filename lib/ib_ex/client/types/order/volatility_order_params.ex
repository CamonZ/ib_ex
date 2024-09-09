defmodule IbEx.Client.Types.Order.VolatilityOrderParams do
  defstruct volatility: nil,
            volatility_type: nil,
            delta_neutral_order_type: nil,
            delta_neutral_aux_price: nil,
            delta_neutral_conid: 0,
            delta_neutral_settling_firm: nil,
            delta_neutral_clearing_account: nil,
            delta_neutral_clearing_intent: nil,
            delta_neutral_open_close: nil,
            delta_neutral_short_sale: false,
            delta_neutral_short_sale_slot: 0,
            delta_neutral_designated_location: nil

  # 1 = daily, 2 = annual
  @type volatility_type :: 1..2

  @type t :: %__MODULE__{
          volatility: Decimal.t(),
          volatility_type: volatility_type(),
          delta_neutral_order_type: binary(),
          delta_neutral_aux_price: Decimal.t(),
          delta_neutral_conid: non_neg_integer(),
          delta_neutral_settling_firm: binary() | none(),
          delta_neutral_clearing_account: binary() | none(),
          delta_neutral_clearing_intent: binary() | none(),
          delta_neutral_open_close: binary() | none(),
          delta_neutral_short_sale: boolean(),
          delta_neutral_short_sale_slot: non_neg_integer(),
          delta_neutral_designated_location: binary() | none()
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

  def serialize(%__MODULE__{} = params) do
    [
      params.volatility,
      params.volatility_type,
      params.delta_neutral_order_type,
      params.delta_neutral_aux_price
    ]
    |> handle_extra_fields(params)
  end

  @spec handle_extra_fields(list(), __MODULE__.t()) :: list()
  def handle_extra_fields(fields, %__MODULE__{volatility_type: type} = params) when type in 1..2 do
    fields ++
      [
        params.delta_neutral_conid,
        params.delta_neutral_settling_firm,
        params.delta_neutral_clearing_account,
        params.delta_neutral_clearing_intent,
        params.delta_neutral_open_close,
        params.delta_neutral_short_sale,
        params.delta_neutral_short_sale_slot,
        params.delta_neutral_designated_location
      ]
  end

  def handle_extra_fields(fields, %__MODULE__{}), do: fields
end
