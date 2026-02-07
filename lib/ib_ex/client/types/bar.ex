defmodule IbEx.Client.Types.Bar do
  @moduledoc """
  Represents a single OHLCV bar from historical data responses.
  """

  defstruct time: nil,
            open: nil,
            high: nil,
            low: nil,
            close: nil,
            volume: nil,
            count: nil,
            wap: nil

  @type t :: %__MODULE__{
          time: binary() | nil,
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
