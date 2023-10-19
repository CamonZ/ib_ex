defmodule IbEx.Client.Messages.Responses.HistoricalTicksLast do
  defstruct request_id: nil, trades: nil

  require Logger

  alias IbEx.Client.Types.Trade

  def from_fields([request_id, amount_of_ticks | ticks_fields]) do
    trades =
      ticks_fields
      |> Enum.chunk_every(6)
      |> Enum.map(&Trade.new/1)
      |> Keyword.get_values(:ok)

    Logger.info("#{amount_of_ticks} Received: #{length(trades)} parsed")
    for trade <- trades, do: Logger.info("#{Trade.to_string(trade)}")

    {:ok,
     %__MODULE__{
       request_id: request_id,
       trades: trades
     }}
  end

  def from_fields(fields) do
    Logger.warning("Trying to parse message as HistoricalTicksLast: #{inspect(fields, limit: :infinity)}")

    {:error, :invalid_args}
  end
end
