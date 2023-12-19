defmodule IbEx.Client.Messages.News.ArticleData do
  @moduledoc """
  Response to the RequestArticle message

  Receives the fields for a %NewsArticle{}
  """

  defstruct request_id: nil, article: nil

  alias IbEx.Client.Types.NewsArticle

  @type t :: %__MODULE__{
          request_id: String.t(),
          article: NewsArticle.t()
        }

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([request_id | rest]) do
    case NewsArticle.from_article_data(rest) do
      {:ok, article} ->
        {:ok, %__MODULE__{request_id: request_id, article: article}}

      _ ->
        {:error, :invalid_args}
    end
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %News.ArticleData{item: #{inspect(msg.item)}}
      """
    end
  end
end
