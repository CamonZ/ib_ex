defmodule IbEx.Client.Types.MarketDepthDescription do
  @moduledoc """
    Represents a description of an exchange offering market depth data 
  """

  alias IbEx.Client.Protocols.Traceable

  defstruct exchange: nil, security_type: nil, listing_exchange: nil, service_data_type: nil, aggregate_group: nil

  def from_market_depth_exchanges([exchange, sec_type, listing_exchange, sd_type, agg_group]) do
    {
      :ok,
      %__MODULE__{
        exchange: exchange,
        security_type: sec_type,
        listing_exchange: listing_exchange,
        service_data_type: sd_type,
        aggregate_group: agg_group
      }
    }
  end

  def from_market_depth_exchanges(_) do
    {:error, :invalid_args}
  end

  defimpl Traceable, for: __MODULE__ do
    def to_s(desc) do
      "%MarketDepthDescription{exchange: #{desc.exchange}, security_type: #{desc.security_type}}"
    end
  end
end
