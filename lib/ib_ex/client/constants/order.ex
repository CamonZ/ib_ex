defmodule IbEx.Client.Constants.Order do
  @moduledoc """
  Order params. 

  * Types.Order
  """

  @actions ~w(BUY SELL)
  @type actions :: :buy | :sell

  # https://www.ibkrguides.com/traderworkstation/order-types.htm 
  @order_types [
    # All or None
    "AOL",
    "IBALGO",
    # Market 
    "MKT",
    # Market-on-Close
    "MOC",
    # Market if Touched
    "MIT",
    "MIDPRICE",
    # Limit
    "LMT",
    # Limit-on-Close
    "LOC",
    # Limit if Touched
    "LIT",
    # Once Cancels All
    "OCA",
    # Stop
    "STP",
    # Stop limit
    "STP LMT",
    "SNAP MKT",
    "SNAP MID",
    "TRAIL",
    "TRAIL LIT",
    "TRAIL MIT",
    "TRAILLIMIT",
    "REL",
    "RPI",
    "PEG BEST",
    # Volatility order 
    "VOL"
  ]

  def actions, do: @actions

  def order_types, do: @order_types

  @spec is_valid_order_type(String.t()) :: boolean()
  def is_valid_order_type(order_type) when order_type in @order_types, do: true
  def is_valid_order_type(_), do: false
end
