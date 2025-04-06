defmodule IbEx.Client.Messages.MarketData.TickNews do
  @moduledoc """
  Message received on news tick market data subscription, receives a news headline
  """

  defstruct request_id: nil, headline: nil

  alias IbEx.Client.Types.NewsHeadline
  alias IbEx.Client.Protocols.Traceable

  @type t :: %__MODULE__{
          request_id: String.t(),
          headline: NewsHeadline.t()
        }

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([request_id | rest]) do
    case NewsHeadline.from_news_tick(rest) do
      {:ok, headline} ->
        {:ok, %__MODULE__{request_id: request_id, headline: headline}}

      _ ->
        {:error, :invalid_args}
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %MarketData.TickNews{
        request_id: #{msg.request_id},
        headline: #{msg.headline.title},
        provider: #{msg.headline.provider},
        provider_id: #{msg.headline.provider_id},
        language: #{msg.headline.language},
        sentiment: #{msg.headline.sentiment},
        extra_metadata: #{inspect(msg.headline.extra_metadata)}
      }
      """
    end
  end

  defimpl IbEx.Client.Protocols.Subscribable, for: __MODULE__ do
    alias IbEx.Client.Subscriptions

    def subscribe(_, _, _) do
      {:error, :response_messages_cannot_create_subscription}
    end

    def lookup(msg, table_ref) do
      Subscriptions.lookup(table_ref, msg.request_id)
    end
  end
end
