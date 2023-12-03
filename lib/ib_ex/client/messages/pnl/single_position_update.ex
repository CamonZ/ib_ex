defmodule IbEx.Client.Messages.Pnl.SinglePositionUpdate do
  @moduledoc """
  Represents a PnL notification of a single position
  """

  alias IbEx.Client.Utils

  defstruct request_id: nil, position: nil, daily_pnl: nil, unrealized_pnl: nil, realized_pnl: nil, value: nil

  def from_fields([request_id, position_str, daily_str, unrealized_str, realized_str, value_str]) do
    {
      :ok,
      %__MODULE__{
        request_id: request_id,
        position: String.to_integer(position_str),
        daily_pnl: Utils.to_decimal(daily_str),
        unrealized_pnl: Utils.to_decimal(unrealized_str),
        realized_pnl: Utils.to_decimal(realized_str),
        value: Utils.to_decimal(value_str)
      }
    }
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- Pnl.SinglePositionUpdate{
        request_id: #{msg.request_id},
        position: #{msg.position},
        daily_pnl: #{msg.daily_pnl},
        unrealized_pnl: #{msg.unrealized_pnl},
        realized_pnl: #{msg.realized_pnl},
        value: #{msg.value}
      }
      """
    end
  end
end
