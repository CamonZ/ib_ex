defmodule IbEx.Client.Messages.Pnl.AllPositionsUpdate do
  @moduledoc """
  Represents a PnL notification
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct request_id: nil, daily_pnl: nil, unrealized_pnl: nil, realized_pnl: nil

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- Pnl.AllPositionsUpdate{
        request_id: #{msg.request_id},
        daily_pnl: #{msg.daily_pnl},
        unrealized_pnl: #{msg.unrealized_pnl},
        realized_pnl: #{msg.realized_pnl}
      }
      """
    end
  end
end
