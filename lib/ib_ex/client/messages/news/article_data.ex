defmodule IbEx.Client.Messages.News.ArticleData do
  @moduledoc """
  Response to the RequestArticle message

  Receives the fields for a %NewsArticle{}
  """

  defstruct request_id: nil, article: nil

  alias IbEx.Client.Protocols.Traceable

  @type t :: %__MODULE__{
          request_id: String.t(),
          article: IbEx.Client.Types.NewsArticle.t()
        }

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %News.ArticleData{item: #{inspect(msg.item)}}
      """
    end
  end
end
