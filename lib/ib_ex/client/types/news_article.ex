defmodule IbEx.Client.Types.NewsArticle do
  @moduledoc """
  Represents a news article
  """

  defstruct type: nil, content: nil

  @type t :: %__MODULE__{
          type: String.t(),
          content: String.t()
        }

  @spec from_article_data(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_article_data([type, content]) do
    {:ok, %__MODULE__{type: type, content: content}}
  end

  def from_article_data(_) do
    {:error, :invalid_args}
  end
end
