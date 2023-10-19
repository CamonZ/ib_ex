defmodule IbEx.Client.Messages.InitConnection.Response do
  @moduledoc """
  The response to the InitConnection message, on the original API it's referred to as the ConnectionAck
  """

  defstruct server_version: nil, server_time: nil

  require Logger

  def from_fields([server_version, timestamp_str] = fields) do
    with {version, _} <- Integer.parse(server_version),
         {:ok, ts} <- parse_timestamp_str(timestamp_str),
         ts <- Timex.Timezone.convert(ts, "Etc/UTC") do
      {:ok,
       %__MODULE__{
         server_version: version,
         server_time: ts
       }}
    else
      _ ->
        Logger.error("Error parsing expected InitConnection / ConnectionAck response: #{inspect(fields)}")
    end
  end

  def from_fields(fields) do
    Logger.warning("Trying to parse message as InitConnection / ConnectionAck response: #{inspect(fields)}")
    {:error, :invalid_args}
  end

  # This is an ugly hack but solves the issue of Timex not being able to parse
  # through %Z the value of "Central European Standard Time"
  defp parse_timestamp_str(timestamp_string) do
    [date, time | _] = String.split(timestamp_string, " ")
    Timex.parse("#{date} #{time} CET", "%Y%m%d %k:%M:%S %Z", :strftime)
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      "<-- %InitConnection{version: #{msg.server_version} timestamp: #{msg.server_time}}"
    end
  end
end
