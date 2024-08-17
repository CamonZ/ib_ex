defmodule IbEx.Client.Messages.MarketData.RequestHistoricalData.UtilsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestHistoricalData.Utils

  describe "format_end_date_time" do
    test "creates valid end_date_time format" do
      {:ok, datetime} = DateTime.new(Date.new!(2024,08,17), Time.new!(17,10,00)) 
      assert Utils.format_end_date_time(datetime) == "20240817 17:10:00Z"
      assert Utils.format_end_date_time(nil) == ""
    end

    test "returns :bad_arguments for bad arguments" do
      assert Utils.format_end_date_time(:bad_arg) == :bad_arguments
    end
  end
  
  describe "get_valid_duration_units" do
    test "returs a list of valid duration_unit values" do
      assert Utils.get_valid_duration_units() == ~w|second day week month year|a
    end
  end

  describe "format_duration" do
    test "creates valid duration format" do
      assert Utils.format_duration({1, :second}) == "1 S"
      assert Utils.format_duration({2, :day}) == "2 D"
      assert Utils.format_duration({3, :week}) == "3 W"
    end

    test "returns :bad_arguments for bad arguments" do
      assert Utils.format_duration({0, :second}) == :bad_arguments
      assert Utils.format_duration({-1, :second}) == :bad_arguments
      assert Utils.format_duration({1, :bad_arg}) == :bad_arguments
      assert Utils.format_duration(:bad_arg) == :bad_arguments
    end
  end
  
  describe "get_valid_bar_size_units" do
    test "returs a list of valid bar_size_unit values" do
      assert Utils.get_valid_bar_size_units() == ~w|second minute hour day week month|a
    end
  end
    
  describe "get_valid_bar_sizes" do
    test "returs a list of valid bar_size values per bar_size_unit" do
      assert Utils.get_valid_bar_sizes(:second) == [1, 5, 10, 15, 30]
      assert Utils.get_valid_bar_sizes(:minute) == [1, 2, 3, 5, 10, 15, 20, 30]
      assert Utils.get_valid_bar_sizes(:hour) == [1, 2, 3, 4, 8]
      assert Utils.get_valid_bar_sizes(:day) == [1]
      assert Utils.get_valid_bar_sizes(:week) == [1]
      assert Utils.get_valid_bar_sizes(:month) == [1]
    end
    test "returns :bad_arguments for bad arguments" do
      assert Utils.get_valid_bar_sizes(:bad_arg) == :bad_arguments
    end
  end

  describe "format_bar_size" do
    test "creates valid bar_size format" do
      assert Utils.format_bar_size({1, :second}) == "1 sec"
      assert Utils.format_bar_size({2, :second}) == "2 secs"
      assert Utils.format_bar_size({1, :minute}) == "1 min"
      assert Utils.format_bar_size({2, :minute}) == "2 mins"
      assert Utils.format_bar_size({1, :hour}) == "1 hour"
      assert Utils.format_bar_size({2, :hour}) == "2 hours"
      assert Utils.format_bar_size({1, :day}) == "1 day"
      assert Utils.format_bar_size({2, :day}) == "2 days"
      assert Utils.format_bar_size({1, :week}) == "1 week"
      assert Utils.format_bar_size({2, :week}) == "2 weeks"
      assert Utils.format_bar_size({1, :month}) == "1 month"
      assert Utils.format_bar_size({2, :month}) == "2 months"
    end

    test "returns :bad_arguments for bad arguments" do
      assert Utils.format_bar_size({0, :second}) == :bad_arguments
      assert Utils.format_bar_size({-1, :second}) == :bad_arguments
      assert Utils.format_bar_size({1, :bad_arg}) == :bad_arguments
      assert Utils.format_bar_size(:bad_arg) == :bad_arguments
    end
  end

  describe "format_what_to_show" do
    test "creates valid what_to_show format" do
      assert Utils.format_what_to_show(:ask) == "ASK"
      assert Utils.format_what_to_show(:bid) == "BID"
      assert Utils.format_what_to_show(:bid_ask) == "BID_ASK"
      assert Utils.format_what_to_show(:fee_rate) == "FEE_RATE"
      assert Utils.format_what_to_show(:historical_volatility) == "HISTORICAL_VOLATILITY"
      assert Utils.format_what_to_show(:midpoint) == "MIDPOINT"
      assert Utils.format_what_to_show(:option_implied_volatility) == "OPTION_IMPLIED_VOLATILITY"
      assert Utils.format_what_to_show(:schedule) == "SCHEDULE"
      assert Utils.format_what_to_show(:trades) == "TRADES"
      assert Utils.format_what_to_show(:yield_ask) == "YIELD_ASK"
      assert Utils.format_what_to_show(:yield_bid_ask) == "YIELD_BID_ASK"
      assert Utils.format_what_to_show(:yield_last) == "YIELD_LAST"
    end

    test "returns :bad_arguments for bad arguments" do
      assert Utils.format_what_to_show("bad_arg") == :bad_arguments
    end
  end
  
  describe "bool_to_int" do
    test "returns 0 for false and 1 for true" do
      assert Utils.bool_to_int(false) == 0
      assert Utils.bool_to_int(true) == 1
    end
    test "returns :bad_arguments for bad arguments" do
      assert Utils.bool_to_int(:not_a_bool) == :bad_arguments
    end
  end
end
