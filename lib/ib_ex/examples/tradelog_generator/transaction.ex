defmodule IbEx.Examples.TradelogGenerator.Transaction do
  defstruct [
    :type,
    :id,
    :symbol,
    :symbol_name,
    :exchange,
    :full_side,
    :side,
    :date,
    :time,
    :account_id,
    :currency,
    :quantity,
    :price,
    :subtotal,
    :commission
  ]

  alias IbEx.Client.Messages.Executions.ExecutionData
  alias IbEx.Client.Messages.Executions.CommissionReport

  @transaction_types %{
    "STK" => "STK_TRD"
  }

  def new(%ExecutionData{execution: exec, contract: contract}, %CommissionReport{} = comm, carry) do
    timestamp = Timex.Timezone.convert(exec.timestamp, "America/New_York")

    transaction = %__MODULE__{
      type: @transaction_types[contract.security_type],
      id: exec.execution_id,
      symbol: contract.symbol,
      exchange: exec.exchange,
      date: DateTime.to_date(timestamp),
      time: DateTime.to_time(timestamp),
      account_id: exec.account_id,
      currency: contract.currency,
      quantity: adjusted_size(exec),
      price: exec.price,
      subtotal: calc_subtotal(exec),
      commission: Decimal.mult(Decimal.new(comm.commission), "-1")
    }

    cond do
      exec.side == "BOT" and carry >= 0 ->
        %{transaction | full_side: "BUYTOOPEN", side: "O"}

      exec.side == "SLD" and carry <= 0 ->
        %{transaction | full_side: "SELLTOOPEN", side: "O"}

      exec.side == "BOT" and carry < 0 and carry + transaction.quantity <= 0 ->
        %{transaction | full_side: "BUYTOCLOSE", side: "C"}

      exec.side == "SLD" and carry > 0 and carry + transaction.quantity >= 0 ->
        %{transaction | full_side: "SELLTOCLOSE", side: "C"}

      exec.side == "BOT" and carry < 0 and carry + transaction.quantity > 0 ->
        %{transaction | full_side: "BUYTOCLOSE", side: "C;O"}

      exec.side == "SLD" and carry > 0 and carry + transaction.quantity < 0 ->
        %{transaction | full_side: "SELLTOCLOSE", side: "C;O"}

      true ->
        transaction
    end
  end

  defp calc_subtotal(execution) do
    price = Decimal.from_float(execution.price)
    size = Decimal.from_float(execution.size)

    subtotal = Decimal.mult(price, size)

    if execution.side == "BOT" do
      Decimal.to_float(subtotal)
    else
      subtotal
      |> Decimal.mult("-1")
      |> Decimal.to_float()
    end
  end

  defp adjusted_size(execution) do
    if execution.side == "BOT" do
      execution.size
    else
      execution.size
      |> Decimal.from_float()
      |> Decimal.mult("-1")
      |> Decimal.to_float()
    end
  end
end
