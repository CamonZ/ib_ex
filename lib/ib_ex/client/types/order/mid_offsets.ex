defmodule IbEx.Client.Types.Order.MidOffsets do
  @moduledoc """
  Serializes the last portion of Order fields - offsets
  """
  alias IbEx.Client.Types.Order

  @spec serialize(Order.t()) :: list()
  def serialize(%Order{order_type: "PEG BEST"} = order) do
    [
      order.min_compete_size,
      order.compete_against_best_offset
    ] ++ add_last_offsets(order)
  end

  def serialize(%Order{order_type: "PEG MID"} = order) do
    add_last_offsets(order)
  end

  def serialize(_), do: []

  @spec add_last_offsets(Order.t()) :: list()
  def add_last_offsets(%Order{compete_against_best_offset: :infinity} = order) do
    [
      order.mid_offset_at_whole,
      order.mid_offset_at_half
    ]
  end

  def add_last_offsets(%Order{}), do: []
end
