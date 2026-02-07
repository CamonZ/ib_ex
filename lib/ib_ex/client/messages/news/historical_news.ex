defmodule IbEx.Client.Messages.News.HistoricalNews do
  @moduledoc """
  Received message with the details of a historical news article
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct request_id: nil, timestamp: nil, provider_code: nil, article_id: nil, headline: nil

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
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
