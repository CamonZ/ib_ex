defmodule IbEx.Client.Constants.BarSizesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Constants.BarSizes

  describe "bar_size_units/1" do
    test "returs a map of valid bar_size_unit values" do
      assert BarSizes.bar_size_units() == %{
               second: "sec",
               month: "month",
               day: "day",
               minute: "min",
               hour: "hour",
               week: "week"
             }
    end
  end

  describe "get_valid_historical_bar_sizes/1" do
    test "returs a list of valid bar_size values per bar_size_unit" do
      assert BarSizes.get_valid_historical_bar_sizes(:second) == [1, 5, 10, 15, 30]
      assert BarSizes.get_valid_historical_bar_sizes(:minute) == [1, 2, 3, 5, 10, 15, 20, 30]
      assert BarSizes.get_valid_historical_bar_sizes(:hour) == [1, 2, 3, 4, 8]
      assert BarSizes.get_valid_historical_bar_sizes(:day) == [1]
      assert BarSizes.get_valid_historical_bar_sizes(:week) == [1]
      assert BarSizes.get_valid_historical_bar_sizes(:month) == [1]
    end

    test "returns :invalid_args for bad arguments" do
      assert BarSizes.get_valid_historical_bar_sizes(:bad_arg) == :invalid_args
    end
  end

  describe "format/1" do
    test "creates valid bar_size format" do
      assert BarSizes.format({1, :second}) == "1 sec"
      assert BarSizes.format({2, :second}) == "2 secs"
      assert BarSizes.format({1, :minute}) == "1 min"
      assert BarSizes.format({2, :minute}) == "2 mins"
      assert BarSizes.format({1, :hour}) == "1 hour"
      assert BarSizes.format({2, :hour}) == "2 hours"
      assert BarSizes.format({1, :day}) == "1 day"
      assert BarSizes.format({2, :day}) == "2 days"
      assert BarSizes.format({1, :week}) == "1 week"
      assert BarSizes.format({2, :week}) == "2 weeks"
      assert BarSizes.format({1, :month}) == "1 month"
      assert BarSizes.format({2, :month}) == "2 months"
    end

    test "returns :invalid_args for bad arguments" do
      assert BarSizes.format({0, :second}) == :invalid_args
      assert BarSizes.format({-1, :second}) == :invalid_args
      assert BarSizes.format({1, :bad_arg}) == :invalid_args
      assert BarSizes.format(:bad_arg) == :invalid_args
    end
  end
end
