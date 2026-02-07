defmodule IbEx.Client.Types.HistoricalTickBidAsk do
  @moduledoc """
  Represents a historical bid/ask tick.

  Tick attribute flags (ask_past_high, bid_past_low) are inlined directly
  on the struct, matching the existing BidAsk type convention.
  """

  defstruct time: nil,
            mask: nil,
            bid_price: nil,
            ask_price: nil,
            bid_size: nil,
            ask_size: nil,
            ask_past_high: nil,
            bid_past_low: nil

  @type t :: %__MODULE__{
          time: non_neg_integer() | nil,
          mask: non_neg_integer() | nil,
          bid_price: float() | nil,
          ask_price: float() | nil,
          bid_size: Decimal.t() | nil,
          ask_size: Decimal.t() | nil,
          ask_past_high: boolean() | nil,
          bid_past_low: boolean() | nil
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
