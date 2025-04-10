defmodule IbEx.Client.Messages.HistoricalTicks.Last do
  defstruct request_id: nil, ticks: nil

  require Logger

  alias IbEx.Client.Types.Trade
  alias IbEx.Client.Protocols.Traceable

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

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- HistoricalTicks{request_id: #{msg.request_id}, ticks: #{inspect(msg.ticks)}}"
    end
  end
end
