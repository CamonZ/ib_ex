defmodule IbEx.Client.Types.RealTimeBar do
  @moduledoc """
  Represents a real-time 5-second bar from the real-time bars subscription.
  """

  defstruct time: nil,
            end_time: nil,
            open: nil,
            high: nil,
            low: nil,
            close: nil,
            volume: nil,
            count: nil,
            wap: nil

  @type t :: %__MODULE__{
          time: binary() | nil,
          end_time: binary() | nil,
          open: float() | nil,
          high: float() | nil,
          low: float() | nil,
          close: float() | nil,
          volume: Decimal.t() | nil,
          count: non_neg_integer() | nil,
          wap: Decimal.t() | nil
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
