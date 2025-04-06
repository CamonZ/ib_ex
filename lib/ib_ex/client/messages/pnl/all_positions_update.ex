defmodule IbEx.Client.Messages.Pnl.AllPositionsUpdate do
  @moduledoc """
  Represents a PnL notification
  """

  alias IbEx.Client.Utils
  alias IbEx.Client.Protocols.Traceable

  defstruct request_id: nil, daily_pnl: nil, unrealized_pnl: nil, realized_pnl: nil

  def from_fields([request_id, daily_str, unrealized_str, realized_str]) do
    {
      :ok,
      %__MODULE__{
        request_id: request_id,
        daily_pnl: Utils.to_decimal(daily_str),
        unrealized_pnl: Utils.to_decimal(unrealized_str),
        realized_pnl: Utils.to_decimal(realized_str)
      }
    }
  rescue
    _ ->
      {:error, :invalid_args}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

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
