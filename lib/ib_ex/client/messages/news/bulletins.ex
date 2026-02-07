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

  alias IbEx.Client.Protocols.Traceable

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
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
