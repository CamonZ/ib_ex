defmodule IbEx.Client.Types.OrderCancel do
  @moduledoc """
  Represent order_cancel params for RequestCancelOrder.
  """

  defstruct manual_order_cancel_time: nil,
            ext_operator: nil,
            external_user_id: nil,
            manual_order_indicator: :unset_integer

  @type t :: %__MODULE__{
          manual_order_cancel_time: binary(),
          ext_operator: binary(),
          external_user_id: binary(),
          manual_order_indicator: non_neg_integer()
        }
  def new(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> new()
  end

  def new(attrs) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end

  def new(), do: new(%{})

  def serialize(%__MODULE__{} = params) do
    [
      params.manual_order_cancel_time,
      params.ext_operator,
      params.external_user_id,
      params.manual_order_indicator
    ]
  end

  def serialize(), do: []
end
