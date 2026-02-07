defmodule IbEx.Client.Types.OrderState do
  @moduledoc """
  Represents the current state of an order as returned by the OpenOrder response.

  Contains order status, margin information (nested MarginInfo), commission
  fields, and allocation details for financial advisor accounts.
  """

  alias IbEx.Client.Types.OrderState.MarginInfo
  alias IbEx.Client.Types.OrderAllocation

  defstruct status: nil,
            margin: nil,
            commission: nil,
            min_commission: nil,
            max_commission: nil,
            commission_currency: nil,
            suggested_size: nil,
            reject_reason: nil,
            warning_text: nil,
            completed_time: nil,
            completed_status: nil,
            allocations: []

  @type t :: %__MODULE__{
          status: binary() | nil,
          margin: MarginInfo.t() | nil,
          commission: float() | nil,
          min_commission: float() | nil,
          max_commission: float() | nil,
          commission_currency: binary() | nil,
          suggested_size: Decimal.t() | nil,
          reject_reason: binary() | nil,
          warning_text: binary() | nil,
          completed_time: binary() | nil,
          completed_status: binary() | nil,
          allocations: list(OrderAllocation.t())
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    attrs =
      args
      |> assign_params(:margin, MarginInfo)

    struct(__MODULE__, attrs)
  end

  def new(), do: new(%{})

  defp assign_params(attrs, key, module) do
    case Map.get(attrs, key) do
      nil -> attrs
      %{__struct__: _} = value -> Map.put(attrs, key, value)
      value when is_map(value) -> Map.put(attrs, key, module.new(value))
      _ -> attrs
    end
  end
end
