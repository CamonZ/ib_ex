defmodule IbEx.Client.Messages.News.RequestHistoricalNews do
  @moduledoc """
  Requests Historical News

  Input parameters are:

  * request_id:
    unique identifier for the request, a number as a string
  * conid
    unique identifier for the financial instrument to request news for
  * providers:
    string with the list of news providers to consume news from separated by a `+` sign, e.g. "BRFG+BGRUPDN"
  * start_ts:
    Start datetime to return news from (exclusive)
  * end_ts:
    End datetime to return news to (inclusive)
  * num_results:
    Max number of results to return (1..300)

  Do note when passing a start and end datetimes that the datetimes will be floored to
  the nearest second

  The final options parameter is currently undocumented in the original API client
  and can be sent to the TWS client as an empty string.
  """

  defstruct message_id: nil,
            request_id: nil,
            conid: nil,
            provider_codes: nil,
            start_timestamp: nil,
            end_timestamp: nil,
            max_results: nil

  @type t :: %__MODULE__{message_id: non_neg_integer()}

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

  @spec new(non_neg_integer(), non_neg_integer(), binary(), DateTime.t(), DateTime.t(), non_neg_integer()) ::
          {:ok, t()} | {:error, :not_implemented}
  def new(request_id, conid, providers, start_ts, end_ts, num_results) do
    case Requests.message_id_for(__MODULE__) do
      {:ok, id} ->
        {
          :ok,
          %__MODULE__{
            message_id: id,
            request_id: request_id,
            conid: conid,
            provider_codes: providers,
            start_timestamp: datetime_to_string(start_ts),
            end_timestamp: datetime_to_string(end_ts),
            max_results: num_results
          }
        }

      :error ->
        {:error, :not_implemented}
    end
  end

  defp datetime_to_string(timestamp) do
    case Timex.format(timestamp, "%Y-%m-%d %H:%M:%S.0", :strftime) do
      {:ok, str} -> str
      _ -> ""
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      fields = [
        msg.message_id,
        msg.request_id,
        msg.conid,
        msg.provider_codes,
        msg.start_timestamp,
        msg.end_timestamp,
        msg.max_results,
        # stand-in for the options field which is internal-use only
        ""
      ]

      Base.build(fields)
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      --> News.RequestHistoricalNews{
        request_id: #{msg.request_id},
        conid: #{msg.conid},
        provider_codes: #{msg.provider_codes},
        start_timestamp: #{msg.start_timestamp},
        end_timestamp: #{msg.end_timestamp},
        max_results: #{msg.max_results}
      }
      """
    end
  end
end
