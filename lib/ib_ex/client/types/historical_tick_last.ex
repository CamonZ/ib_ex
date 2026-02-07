defmodule IbEx.Client.Types.HistoricalTickLast do
  @moduledoc """
  Represents a historical last-traded tick.

  Tick attribute flags (past_limit, unreported) are inlined directly
  on the struct, matching the existing Trade type convention.
  """

  defstruct time: nil,
            mask: nil,
            price: nil,
            size: nil,
            exchange: nil,
            conditions: nil,
            past_limit: nil,
            unreported: nil

  @type t :: %__MODULE__{
          time: non_neg_integer() | nil,
          mask: non_neg_integer() | nil,
          price: float() | nil,
          size: Decimal.t() | nil,
          exchange: binary() | nil,
          conditions: binary() | nil,
          past_limit: boolean() | nil,
          unreported: boolean() | nil
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
