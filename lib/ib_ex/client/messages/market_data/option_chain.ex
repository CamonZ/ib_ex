defmodule IbEx.Client.Messages.MarketData.OptionChain do
  @moduledoc """
  Returned option chain struct 
  """

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

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([_, request_id, exchange, conid, symbol, multiplier, expirations_length | rest]) do
    expirations_length = String.to_integer(expirations_length)
    expirations = Enum.slice(rest, 0, expirations_length)
    strikes_length = Enum.slice(rest, expirations_length, 1) |> Enum.at(0) |> String.to_integer()
    strikes = Enum.slice(rest, -strikes_length..-1)

    msg = %__MODULE__{
      request_id: request_id,
      exchange: exchange,
      underlying_conid: conid,
      underlying_symbol: symbol,
      multiplier: multiplier,
      expirations: expirations,
      strikes: strikes
    }

    {:ok, msg}
  end

  def from_fields(_) do
    {:error, :invalid_args}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
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
