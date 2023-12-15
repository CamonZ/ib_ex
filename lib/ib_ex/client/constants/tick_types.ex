defmodule IbEx.Client.Constants.TickTypes do
  @moduledoc """
  Tick types definition.

  It is used to determine the type of a tick message
  on the messages:

  * MarketData.TickPrice
  """

  @types {
    :bid_size,
    :bid,
    :ask,
    :ask_size,
    :last,
    :last_size,
    :high,
    :low,
    :volume,
    :close,
    :bid_option_computation,
    :ask_option_computation,
    :last_option_computation,
    :model_option,
    :open,
    :low_13_week,
    :high_13_week,
    :low_26_week,
    :high_26_week,
    :low_52_week,
    :high_52_week,
    :avg_volume,
    :open_interest,
    :option_historical_vol,
    :option_implied_vol,
    :option_bid_exch,
    :option_ask_exch,
    :option_call_open_interest,
    :option_put_open_interest,
    :option_call_volume,
    :option_put_volume,
    :index_future_premium,
    :bid_exch,
    :ask_exch,
    :auction_volume,
    :auction_price,
    :auction_imbalance,
    :mark_price,
    :bid_efp_computation,
    :ask_efp_computation,
    :last_efp_computation,
    :open_efp_computation,
    :high_efp_computation,
    :low_efp_computation,
    :close_efp_computation,
    :last_timestamp,
    :shortable,
    :fundamental_ratios,
    :rt_volume,
    :halted,
    :bid_yield,
    :ask_yield,
    :last_yield,
    :cust_option_computation,
    :trade_count,
    :trade_rate,
    :volume_rate,
    :last_rth_trade,
    :rt_historical_vol,
    :ib_dividends,
    :bond_factor_multiplier,
    :regulatory_imbalance,
    :news_tick,
    :short_term_volume_3_min,
    :short_term_volume_5_min,
    :short_term_volume_10_min,
    :delayed_bid,
    :delayed_ask,
    :delayed_last,
    :delayed_bid_size,
    :delayed_ask_size,
    :delayed_last_size,
    :delayed_high,
    :delayed_low,
    :delayed_volume,
    :delayed_close,
    :delayed_open,
    :rt_trd_volume,
    :creditman_mark_price,
    :creditman_slow_mark_price,
    :delayed_bid_option,
    :delayed_ask_option,
    :delayed_last_option,
    :delayed_model_option,
    :last_exch,
    :last_reg_time,
    :futures_open_interest,
    :avg_opt_volume,
    :delayed_last_timestamp,
    :shortable_shares,
    :delayed_halted,
    :reuters_2_mutual_funds,
    :etf_nav_close,
    :etf_nav_prior_close,
    :etf_nav_bid,
    :etf_nav_ask,
    :etf_nav_last,
    :etf_frozen_nav_last,
    :etf_nav_high,
    :etf_nav_low,
    :social_market_analytics,
    :estimated_ipo_midpoint,
    :final_ipo_last,
    :delayed_yield_bid,
    :delayed_yield_ask,
    :not_set
  }

  alias IbEx.Client.Utils

  @spec to_atom(any()) :: {:ok, atom()} | {:error, :invalid_args}
  def to_atom(index_str) when is_binary(index_str) do
    case Utils.to_integer(index_str) do
      nil -> {:error, :invalid_args}
      index -> to_atom(index)
    end
  end

  def to_atom(index) when is_integer(index) and index >= 0 do
    case index <= tuple_size(@types) - 1 do
      true -> {:ok, elem(@types, index)}
      false -> {:error, :invalid_args}
    end
  end

  def to_atom(_) do
    {:error, :invalid_args}
  end

  @spec size_related_type?(atom()) :: boolean()
  def size_related_type?(type) when is_atom(type) do
    type in [
      :bid_size,
      :ask_size,
      :last_size,
      :delayed_bid_size,
      :delayed_ask_size,
      :delate_last_size
    ]
  end

  def size_related_type?(_) do
    false
  end
end
