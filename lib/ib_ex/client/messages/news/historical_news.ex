defmodule IbEx.Client.Messages.News.HistoricalNews do
  @moduledoc """
  Received message with the details of a historical news article
  """

  defstruct request_id: nil, timestamp: nil, provider_code: nil, article_id: nil, headline: nil

  # TODO: Refactor this message to use the NewsHeadline type

  def from_fields([request_id, timestamp, provider_code, article_id, headline]) do
    {
      :ok,
      %__MODULE__{
        request_id: request_id,
        timestamp: timestamp,
        provider_code: provider_code,
        article_id: article_id,
        headline: headline
      }
    }
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %News.HistoricalNews{
        request_id: #{msg.request_id},
        timestamp: #{msg.timestamp},
        provider_code: #{msg.provider_code},
        article_id: #{msg.article_id},
        headline: #{msg.headline}
       }
      """
    end
  end
end
