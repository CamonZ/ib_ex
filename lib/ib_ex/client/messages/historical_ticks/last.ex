defmodule IbEx.Client.Messages.HistoricalTicks.Last do
  defstruct request_id: nil, ticks: nil

  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      "<-- HistoricalTicks{request_id: #{msg.request_id}, ticks: #{inspect(msg.ticks)}}"
    end
  end
end
