defmodule IbEx.Client.Messages.MarketData.Tick.OptionComputation do
  @moduledoc """
  Option computation message from subscribing to
  the market data request for an option Contract.

  Represents a generic tick.
  """

  defstruct request_id: nil,
            tick_type: nil,
            tick_attr: nil,
            implied_volatility: nil,
            delta: nil,
            option_price: nil,
            pv_dividend: nil,
            gamma: nil,
            vega: nil,
            theta: nil,
            underlying_price: nil

  @type t :: %__MODULE__{
          request_id: String.t(),
          tick_type: atom(),
          tick_attr: non_neg_integer(),
          implied_volatility: Decimal.t(),
          delta: Decimal.t(),
          option_price: Decimal.t(),
          pv_dividend: Decimal.t(),
          gamma: Decimal.t(),
          vega: Decimal.t(),
          theta: Decimal.t(),
          underlying_price: Decimal.t()
        }

  alias IbEx.Client.Utils

  @spec from_fields(list(String.t())) :: {:ok, t()} | {:error, :invalid_args}
  def from_fields([
        _,
        request_id,
        tick_type,
        tick_attr,
        iv,
        delta,
        option_price,
        pv_dividend,
        gamma,
        vega,
        theta,
        underlying_price
      ]) do
    tick_type = Utils.decode_tick_type(tick_type)

    msg = %__MODULE__{
      request_id: request_id,
      tick_type: tick_type,
      tick_attr: Utils.to_integer(tick_attr),
      implied_volatility: Utils.to_decimal(iv),
      delta: Utils.to_decimal(delta),
      option_price: Utils.to_decimal(option_price),
      pv_dividend: Utils.to_decimal(pv_dividend),
      gamma: Utils.to_decimal(gamma),
      vega: Utils.to_decimal(vega),
      theta: Utils.to_decimal(theta),
      underlying_price: Utils.to_decimal(underlying_price)
    }

    {:ok, msg}
  end

  def from_fields(args) do
    {:error, :invalid_args, [__ENV__.function, args]}
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(msg, _opts) do
      """
      <-- %MarketData.Tick.OptionComputation{
        request_id: #{msg.request_id},
        tick_type: #{msg.tick_type},
        tick_attr: #{msg.tick_attr},
        option_price: #{msg.option_price},
        underlying_price: #{msg.underlying_price},
        implied_volatility: #{msg.implied_volatility},
        delta: #{msg.delta},
        gamma: #{msg.gamma},
        vega: #{msg.vega},
        theta: #{msg.theta},
        pv_dividend: #{msg.pv_dividend}
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
