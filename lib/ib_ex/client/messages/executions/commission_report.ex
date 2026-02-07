defmodule IbEx.Client.Messages.Executions.CommissionReport do
  defstruct execution_id: nil,
            commission: nil,
            currency: nil,
            realized_pnl: nil,
            yield: nil,
            yield_redemption_date: nil

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
        <-- CommissionReport{
            execution_id: #{msg.execution_id},
            commission: #{msg.commission},
            currency: #{msg.currency},
            realized_pnl: #{msg.realized_pnl},
            yield: #{msg.yield},
            yield_redemption_date: #{msg.yield_redemption_date}
          }
      """
    end
  end

  defimpl Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions
    alias IbEx.Client.Messages.Executions.CommissionReport

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(%CommissionReport{} = msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.execution_id)
    end
  end
end
