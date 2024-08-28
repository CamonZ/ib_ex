defmodule IbEx.Client.Types.ScaleOrderParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Order.{
    ScaleOrderParams
  }

  describe "new/0" do
    test "creates a ScaleOrderParams struct with default attributes" do
      assert ScaleOrderParams.new() == %ScaleOrderParams{
               init_level_size: nil,
               subs_level_size: nil,
               price_increment: nil,
               price_adjust_value: nil,
               price_adjust_interval: nil,
               profit_offset: nil,
               auto_reset: false,
               init_position: nil,
               init_fill_quantity: nil,
               random_percent: false,
               table: nil,
               active_start_time: nil,
               active_stop_time: nil
             }
    end
  end

  describe "new/1" do
    test "creates a ScaleOrderParams struct with valid attributes" do
      attrs = %{
        init_level_size: 14,
        subs_level_size: 15,
        price_increment: 1,
        price_adjust_value: Decimal.new("16"),
        price_adjust_interval: 1,
        profit_offset: Decimal.new("17"),
        auto_reset: false,
        init_position: 5,
        init_fill_quantity: 2,
        random_percent: true,
        table: "table",
        active_start_time: "20240908 13:14:15",
        active_stop_time: "20240908 14:15:16"
      }

      assert ScaleOrderParams.new(attrs) == %ScaleOrderParams{
               init_level_size: 14,
               subs_level_size: 15,
               price_increment: 1,
               price_adjust_value: Decimal.new("16"),
               price_adjust_interval: 1,
               profit_offset: Decimal.new("17"),
               auto_reset: false,
               init_position: 5,
               init_fill_quantity: 2,
               random_percent: true,
               table: "table",
               active_start_time: "20240908 13:14:15",
               active_stop_time: "20240908 14:15:16"
             }
    end
  end

  describe "serialize/1" do
    test "serializes with price_increment == nil" do
      params = %{
        init_level_size: 14,
        subs_level_size: 15,
        price_increment: nil,
        price_adjust_value: Decimal.new("16"),
        price_adjust_interval: 1,
        profit_offset: Decimal.new("17"),
        auto_reset: false,
        init_position: 5,
        init_fill_quantity: 2,
        random_percent: true,
        table: "table",
        active_start_time: "20240908 13:14:15",
        active_stop_time: "20240908 14:15:16"
      }

      assert ScaleOrderParams.new(params) |> ScaleOrderParams.serialize() == [
               params.init_level_size,
               params.subs_level_size,
               params.price_increment,
               params.table,
               params.active_start_time,
               params.active_stop_time
             ]
    end

    test "serializes with price_increment > 0" do
      params = %{
        init_level_size: 14,
        subs_level_size: 15,
        price_increment: 1,
        price_adjust_value: Decimal.new("16"),
        price_adjust_interval: 1,
        profit_offset: Decimal.new("17"),
        auto_reset: false,
        init_position: 5,
        init_fill_quantity: 2,
        random_percent: true,
        table: "table",
        active_start_time: "20240908 13:14:15",
        active_stop_time: "20240908 14:15:16"
      }

      assert ScaleOrderParams.new(params) |> ScaleOrderParams.serialize() == [
               params.init_level_size,
               params.subs_level_size,
               params.price_increment,
               params.price_adjust_value,
               params.price_adjust_interval,
               params.profit_offset,
               params.auto_reset,
               params.init_position,
               params.init_fill_quantity,
               params.random_percent,
               params.table,
               params.active_start_time,
               params.active_stop_time
             ]
    end
  end
end
