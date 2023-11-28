defmodule IbEx.Client.Messages.HistoricalTicks.Last do
  defstruct request_id: nil, ticks: nil

  require Logger

  alias IbEx.Client.Types.Trade

  def from_fields([request_id, _amount_of_ticks | ticks_fields]) do
    trades =
      ticks_fields
      |> Enum.chunk_every(6)
      |> Enum.map(&Trade.from_historical_ticks_last/1)
      |> Keyword.get_values(:ok)

    {:ok,
     %__MODULE__{
       request_id: request_id,
       ticks: trades
     }}
  end

  def from_fields(_fields) do
    {:error, :invalid_args}
  end
end
