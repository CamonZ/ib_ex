defmodule IbEx.Client.Messages.Misc.CommissionReport do
  defstruct version: nil,
            exec_id: nil,
            commission: nil,
            currency: nil,
            realized_pnl: nil,
            yield: nil,
            yield_redemption_date: nil

  require Logger

  def from_fields(fields) when length(fields) == 7 do
    [version, exec_id, commission, currency, realized, yield, redemption_date] = fields

    msg = %__MODULE__{
      version: String.to_integer(version),
      exec_id: exec_id,
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

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
        <-- CommissionReport{
            version: #{msg.version},
            exec_id: #{msg.exec_id}},
            commission: #{msg.commission},
            currency: #{msg.currency},
            realized_pnl: #{msg.realized_pnl},
            yield: #{msg.yield},
            yield_redemption_date: #{msg.yield_redemption_date}
          }
      """
    end
  end
end
