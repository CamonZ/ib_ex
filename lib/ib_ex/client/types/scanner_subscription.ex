defmodule IbEx.Client.Types.ScannerSubscription do
  @moduledoc """
  Represents a scanner subscription with filter criteria for the market scanner.
  """

  defstruct number_of_rows: -1,
            instrument: nil,
            location_code: nil,
            scan_code: nil,
            above_price: nil,
            below_price: nil,
            above_volume: nil,
            market_cap_above: nil,
            market_cap_below: nil,
            moody_rating_above: nil,
            moody_rating_below: nil,
            sp_rating_above: nil,
            sp_rating_below: nil,
            maturity_date_above: nil,
            maturity_date_below: nil,
            coupon_rate_above: nil,
            coupon_rate_below: nil,
            exclude_convertible: nil,
            average_option_volume_above: nil,
            scanner_setting_pairs: nil,
            stock_type_filter: nil

  @type t :: %__MODULE__{
          number_of_rows: integer(),
          instrument: binary() | nil,
          location_code: binary() | nil,
          scan_code: binary() | nil,
          above_price: float() | nil,
          below_price: float() | nil,
          above_volume: non_neg_integer() | nil,
          market_cap_above: float() | nil,
          market_cap_below: float() | nil,
          moody_rating_above: binary() | nil,
          moody_rating_below: binary() | nil,
          sp_rating_above: binary() | nil,
          sp_rating_below: binary() | nil,
          maturity_date_above: binary() | nil,
          maturity_date_below: binary() | nil,
          coupon_rate_above: float() | nil,
          coupon_rate_below: float() | nil,
          exclude_convertible: boolean() | nil,
          average_option_volume_above: non_neg_integer() | nil,
          scanner_setting_pairs: binary() | nil,
          stock_type_filter: binary() | nil
        }

  def new(args) when is_list(args) do
    args
    |> Enum.into(%{})
    |> new()
  end

  def new(args) when is_map(args) do
    struct(__MODULE__, args)
  end

  def new(), do: new(%{})
end
