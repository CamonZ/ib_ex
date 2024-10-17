defmodule IbEx.Client.Types.Order.DeltaNeutralParams do
  defstruct order_type: nil,
            aux_price: nil,
            conid: 0,
            settling_firm: nil,
            clearing_account: nil,
            clearing_intent: nil,
            open_close: nil,
            short_sale: false,
            short_sale_slot: 0,
            designated_location: nil

  @type t :: %__MODULE__{
          order_type: binary(),
          aux_price: Decimal.t(),
          conid: non_neg_integer(),
          settling_firm: binary() | none(),
          clearing_account: binary() | none(),
          clearing_intent: binary() | none(),
          open_close: binary() | none(),
          short_sale: boolean(),
          short_sale_slot: non_neg_integer(),
          designated_location: binary() | none()
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
      params.order_type,
      params.aux_price
    ]
    |> handle_extra_fields(params)
  end

  @spec handle_extra_fields(list(), __MODULE__.t()) :: list()
  def handle_extra_fields(fields, %__MODULE__{order_type: ""}), do: fields

  def handle_extra_fields(fields, %__MODULE__{order_type: type} = params) when is_binary(type) do
    fields ++
      [
        params.conid,
        params.settling_firm,
        params.clearing_account,
        params.clearing_intent,
        params.open_close,
        params.short_sale,
        params.short_sale_slot,
        params.designated_location
      ]
  end

  def handle_extra_fields(fields, %__MODULE__{}), do: fields
end
