defmodule IbEx.Client.Types.ScannerSubscriptionTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.ScannerSubscription

  describe "new/0" do
    test "creates a ScannerSubscription struct with default attributes" do
      result = ScannerSubscription.new()

      assert result.number_of_rows == -1
      assert result.instrument == nil
      assert result.location_code == nil
      assert result.scan_code == nil
      assert result.above_price == nil
      assert result.below_price == nil
      assert result.above_volume == nil
      assert result.market_cap_above == nil
      assert result.market_cap_below == nil
      assert result.moody_rating_above == nil
      assert result.moody_rating_below == nil
      assert result.sp_rating_above == nil
      assert result.sp_rating_below == nil
      assert result.maturity_date_above == nil
      assert result.maturity_date_below == nil
      assert result.coupon_rate_above == nil
      assert result.coupon_rate_below == nil
      assert result.exclude_convertible == nil
      assert result.average_option_volume_above == nil
      assert result.scanner_setting_pairs == nil
      assert result.stock_type_filter == nil
    end
  end

  describe "new/1" do
    test "creates a ScannerSubscription struct from a map" do
      params = %{
        number_of_rows: 50,
        instrument: "STK",
        location_code: "STK.US.MAJOR",
        scan_code: "TOP_PERC_GAIN",
        above_price: 5.0,
        below_price: 100.0,
        above_volume: 1000,
        market_cap_above: 1_000_000.0,
        exclude_convertible: true,
        stock_type_filter: "ALL"
      }

      result = ScannerSubscription.new(params)

      assert result.number_of_rows == 50
      assert result.instrument == "STK"
      assert result.location_code == "STK.US.MAJOR"
      assert result.scan_code == "TOP_PERC_GAIN"
      assert result.above_price == 5.0
      assert result.below_price == 100.0
      assert result.above_volume == 1000
      assert result.market_cap_above == 1_000_000.0
      assert result.exclude_convertible == true
      assert result.stock_type_filter == "ALL"
    end

    test "creates a ScannerSubscription struct from a keyword list" do
      params = [
        instrument: "STK",
        scan_code: "HOT_BY_VOLUME",
        number_of_rows: 25
      ]

      result = ScannerSubscription.new(params)

      assert result.instrument == "STK"
      assert result.scan_code == "HOT_BY_VOLUME"
      assert result.number_of_rows == 25
      assert result.location_code == nil
    end
  end
end
