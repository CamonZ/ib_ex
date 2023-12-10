defmodule IbEx.Client.Messages.News.Bulletins do
  @moduledoc """
  Response to the RequestBulletins message

  Receives a bulletin message

  The parameters are:

  * Type: The type of message, can be one of: 
    * Regular news bulletin
    * Exchange no longer available for trading
    * Exchange is available for trading
  * Message: The received message
  * Exchange: The exchange where the message comes from 
  """

  defstruct type: nil, message: nil, exchange: nil

  def from_fields([type, message, exchange]) do
    {
      :ok,
      %__MODULE__{
        type: parse_type(type),
        message: message,
        exchange: exchange
      }
    }
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defp parse_type(type_str) do
    case type_str do
      "1" -> "regular_news"
      "2" -> "exchange_not_available"
      "3" -> "exchange_available"
      _ -> "other"
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %News.Bulletins{
        type: #{msg.type},
        message: #{msg.message},
        exchange: #{msg.exchange}
      }
      """
    end
  end
end
