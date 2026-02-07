defmodule IbEx.Client.Messages.MarketData.OptionChain do
  @moduledoc """
  Returned option chain struct 
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct request_id: nil,
            exchange: nil,
            underlying_conid: nil,
            underlying_symbol: nil,
            multiplier: nil,
            expirations: [],
            strikes: []

  @type t :: %__MODULE__{
          request_id: String.t(),
          exchange: binary(),
          underlying_conid: binary(),
          underlying_symbol: binary(),
          multiplier: non_neg_integer(),
          expirations: list(binary()),
          strikes: list(Decimal.t())
        }

  defimpl Traceable, for: __MODULE__ do
    def to_s(msg) do
      """
      <-- %MarketData.OptionChain{
        request_id: #{msg.request_id},
        exchange: #{msg.exchange},
        underlying_conid: #{msg.underlying_conid},
        underlying_symbol: #{msg.underlying_symbol},
        multiplier: #{msg.multiplier},
        expirations: #{Enum.join(msg.expirations, ", ")},
        strikes: #{Enum.join(msg.strikes, ", ")},
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
