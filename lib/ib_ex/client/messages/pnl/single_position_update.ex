defmodule IbEx.Client.Messages.Pnl.SinglePositionUpdate do
  @moduledoc """
  Represents a PnL notification of a single position
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct request_id: nil, position: nil, daily_pnl: nil, unrealized_pnl: nil, realized_pnl: nil, value: nil

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
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
