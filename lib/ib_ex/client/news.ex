defmodule IbEx.Client.News do
  @moduledoc """
  Thematic module for news operations.

  Provides high-level functions for querying news providers, fetching news
  articles, requesting historical news, and subscribing to news bulletins.
  This module is stateless -- it builds proto request structs and delegates
  to `Client.request/3`, `Client.subscribe/3`, and `Client.unsubscribe/2`.

  ## Functions

  * `providers/2` - Requests the list of available news providers
    (single request/response, global correlation).
  * `article/3` - Requests a specific news article by provider code and article ID
    (single request/response, req_id correlation).
  * `historical/3` - Requests historical news headlines for a contract
    (bounded stream: accumulates HistoricalNews responses, ends with HistoricalNewsEnd).
  * `subscribe_bulletins/2` - Subscribes to IB news bulletins
    (continuous global stream of NewsBulletin messages).
  * `unsubscribe_bulletins/1` - Cancels a news bulletins subscription.
  """

  alias IbEx.Client
  alias IbEx.Client.Proto.Protobuf, as: Proto

  @doc """
  Requests the list of available news providers.

  Sends a `NewsProvidersRequest` through `Client.request/3` using global correlation.

  Returns `{:ok, %Proto.NewsProviders{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.NewsProviders{news_providers: providers}} = News.providers(client)

  """
  @spec providers(pid(), keyword()) :: {:ok, struct()} | {:error, any()}
  def providers(client, opts \\ []) do
    request = %Proto.NewsProvidersRequest{}
    Client.request(client, request, opts)
  end

  @doc """
  Requests a specific news article.

  Sends a `NewsArticleRequest` through `Client.request/3` using req_id correlation.

  Returns `{:ok, %Proto.NewsArticle{}}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:news_article_options` - Map of additional options (default: `%{}`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, %Proto.NewsArticle{article_type: type, article_text: text}} =
        News.article(client, "BRFG", "BRFG$12345678")

  """
  @spec article(pid(), String.t(), String.t(), keyword()) :: {:ok, struct()} | {:error, any()}
  def article(client, provider_code, article_id, opts \\ []) do
    request = %Proto.NewsArticleRequest{
      provider_code: provider_code,
      article_id: article_id,
      news_article_options: Keyword.get(opts, :news_article_options, %{})
    }

    Client.request(client, request, opts)
  end

  @doc """
  Requests historical news headlines for the given contract ID.

  Sends a `HistoricalNewsRequest` through `Client.request/3` as a bounded stream.
  The response accumulates `HistoricalNews` protos and ends with a `HistoricalNewsEnd`
  marker.

  Returns `{:ok, [%Proto.HistoricalNews{}, ...]}` on success (accumulated list),
  or `{:error, reason}` on failure.

  ## Options

  * `:provider_codes` - Comma-separated string of provider codes to filter (default: `""`)
  * `:start_date_time` - Start date/time string (default: `""`)
  * `:end_date_time` - End date/time string (default: `""`)
  * `:total_results` - Maximum number of results to return (default: `10`)
  * `:historical_news_options` - Map of additional options (default: `%{}`)
  * `:timeout` - Request timeout in milliseconds (default: `5_000`)

  ## Examples

      {:ok, headlines} = News.historical(client, 265598, provider_codes: "BRFG+BRFUPDN")

  """
  @spec historical(pid(), integer(), keyword()) :: {:ok, list()} | {:error, any()}
  def historical(client, con_id, opts \\ []) when is_integer(con_id) do
    request = %Proto.HistoricalNewsRequest{
      con_id: con_id,
      provider_codes: Keyword.get(opts, :provider_codes, ""),
      start_date_time: Keyword.get(opts, :start_date_time, ""),
      end_date_time: Keyword.get(opts, :end_date_time, ""),
      total_results: Keyword.get(opts, :total_results, 10),
      historical_news_options: Keyword.get(opts, :historical_news_options, %{})
    }

    Client.request(client, request, opts)
  end

  @doc """
  Subscribes to IB news bulletins.

  Sends a `NewsBulletinsRequest` through `Client.subscribe/3` using global correlation.
  The caller receives `{:ib_ex, subscription_ref, msg}` messages with `NewsBulletin` protos.

  Returns `{:ok, subscription_ref}` on success, or `{:error, reason}` on failure.

  ## Options

  * `:all_messages` - If `true`, returns all existing bulletins for the current day
    in addition to new ones (default: `true`)

  ## Examples

      {:ok, ref} = News.subscribe_bulletins(client)

  """
  @spec subscribe_bulletins(pid(), keyword()) :: {:ok, reference()} | {:error, any()}
  def subscribe_bulletins(client, opts \\ []) do
    request = %Proto.NewsBulletinsRequest{
      all_messages: Keyword.get(opts, :all_messages, true)
    }

    Client.subscribe(client, request, opts)
  end

  @doc """
  Cancels a news bulletins subscription.

  Delegates to `Client.unsubscribe/2` which sends a `CancelNewsBulletins` message
  and removes the subscription.

  Returns `:ok` on success, or `{:error, :not_found}` if the subscription does not exist.

  ## Examples

      :ok = News.unsubscribe_bulletins(client, subscription_ref)

  """
  @spec unsubscribe_bulletins(pid(), reference()) :: :ok | {:error, :not_found}
  def unsubscribe_bulletins(client, subscription_ref) do
    Client.unsubscribe(client, subscription_ref)
  end
end
