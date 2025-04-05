defmodule IbEx.Client.Messages.News.RequestArticle do
  @moduledoc """
  Message used to request a specific news article by a given provider
  """

  defstruct message_id: nil, request_id: nil, provider_code: nil, provider_id: nil, options: []

  @type t :: %__MODULE__{
          message_id: non_neg_integer(),
          request_id: non_neg_integer(),
          provider_code: String.t(),
          provider_id: String.t(),
          options: list(none())
        }

  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

  @spec new(non_neg_integer(), String.t(), String.t()) :: {:ok, t()}
  def new(request_id, provider_code, provider_id) do
    {:ok, message_id} = Requests.message_id_for(__MODULE__)

    {
      :ok,
      %__MODULE__{
        message_id: message_id,
        request_id: request_id,
        provider_code: provider_code,
        provider_id: provider_id
      }
    }
  end

  defimpl String.Chars, for: __MODULE__ do
    alias IbEx.Client.Messages.Base

    def to_string(msg) do
      Base.build([
        msg.message_id,
        msg.request_id,
        msg.provider_code,
        msg.provider_id,
        ""
      ])
    end
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %News.RequestArticle{
        request_id: #{msg.request_id},
        provider_code: #{msg.provider_code},
        provider_id: #{msg.provider_id}
       }
      """
    end
  end
end
