defmodule IbEx.Client.Types.Order.VolatilityOrderParams do
  defstruct volatility: nil,
            volatility_type: nil,
            delta_neutral_order_type: nil,
            delta_neutral_aux_price: nil,
            delta_neutral_conid: nil,
            delta_neutral_settling_firm: nil,
            delta_neutral_clearing_account: nil,
            delta_neutral_clearing_intent: nil,
            delta_neutral_open_close: nil,
            delta_neutral_short_sale: nil,
            delta_neutral_short_sale_slot: nil,
            delta_neutral_designated_location: nil,
            continuous_update: nil,
            reference_price_type: nil

  @type t :: %__MODULE__{
          volatility: Decimal.t(),
          # 1=daily, 2=annual
          volatility_type: 1..2,
          delta_neutral_order_type: binary(),
          delta_neutral_aux_price: Decimal.t(),
          delta_neutral_conid: non_neg_integer(),
          delta_neutral_settling_firm: binary() | none(),
          delta_neutral_clearing_account: binary() | none(),
          delta_neutral_clearing_intent: binary() | none(),
          delta_neutral_open_close: binary() | none(),
          delta_neutral_short_sale: boolean(),
          delta_neutral_short_sale_slot: non_neg_integer(),
          delta_neutral_designated_location: binary() | none(),
          continuous_update: non_neg_integer() | none(),
          reference_price_type: non_neg_integer()
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
