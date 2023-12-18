defmodule IbEx.Client.Messages.MarketData.MarketDataType do
  @moduledoc """
  Message received when the data type being received switches between frozen
  and realtime.
  """

  defstruct request_id: nil, data_type: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          data_type: atom()
        }

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([_, request_id, data_type_str]) do
    {
      :ok,
      %__MODULE__{
        request_id: request_id,
        data_type: parse_market_data_type(data_type_str)
      }
    }
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defp parse_market_data_type(data_type_str) do
    case data_type_str do
      "1" -> :live
      "2" -> :frozen
      "3" -> :delayed
      "4" -> :delayed_frozen
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- %MarketData.MarketDataType{request_id: #{msg.request_id}, data_type: #{msg.data_type}}"
    end
  end
end
