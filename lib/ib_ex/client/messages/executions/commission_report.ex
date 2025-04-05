defmodule IbEx.Client.Messages.Executions.CommissionReport do
  defstruct version: nil,
            execution_id: nil,
            commission: nil,
            currency: nil,
            realized_pnl: nil,
            yield: nil,
            yield_redemption_date: nil

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable

  def from_fields(fields) when length(fields) == 7 do
    [version, exec_id, commission, currency, realized, yield, redemption_date] = fields

    msg = %__MODULE__{
      version: String.to_integer(version),
      execution_id: exec_id,
      commission: commission,
      currency: String.upcase(currency),
      realized_pnl: realized,
      yield: yield,
      yield_redemption_date: redemption_date
    }

    {:ok, msg}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
        <-- CommissionReport{
            version: #{msg.version},
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

  # variant of subscribable lookup, in this case we want to relay
  # this commission report to whichever process is receiving
  # the execution data this report is paired to
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
