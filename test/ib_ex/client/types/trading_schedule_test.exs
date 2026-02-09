defmodule IbEx.Client.Types.TradingScheduleTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.TradingSchedule
  alias IbEx.Client.Types.TradingSession

  describe "parse/1 with a full schedule string" do
    test "parses semicolon-delimited string into list of TradingSession structs" do
      schedule = "20260208:CLOSED;20260209:0400-20260209:2000;20260210:0400-20260210:2000"

      result = TradingSchedule.parse(schedule)

      assert length(result) == 3

      assert [closed_day, open_day_1, open_day_2] = result

      assert %TradingSession{date: ~D[2026-02-08], status: :closed, open: nil, close: nil} = closed_day

      assert %TradingSession{date: ~D[2026-02-09], status: :open, open: ~T[04:00:00], close: ~T[20:00:00]} =
               open_day_1

      assert %TradingSession{date: ~D[2026-02-10], status: :open, open: ~T[04:00:00], close: ~T[20:00:00]} =
               open_day_2
    end

    test "parses a single CLOSED entry" do
      result = TradingSchedule.parse("20260208:CLOSED")

      assert [%TradingSession{date: ~D[2026-02-08], status: :closed}] = result
    end

    test "parses a single open entry" do
      result = TradingSchedule.parse("20260209:0930-20260209:1600")

      assert [%TradingSession{date: ~D[2026-02-09], status: :open, open: ~T[09:30:00], close: ~T[16:00:00]}] = result
    end
  end

  describe "parse/1 with nil or empty input" do
    test "returns empty list for nil" do
      assert TradingSchedule.parse(nil) == []
    end

    test "returns empty list for empty string" do
      assert TradingSchedule.parse("") == []
    end
  end

  describe "parse/1 skips invalid entries" do
    test "skips entries that fail to parse" do
      schedule = "20260208:CLOSED;invalid;20260209:0400-20260209:2000"

      result = TradingSchedule.parse(schedule)

      assert length(result) == 2
      assert [%TradingSession{status: :closed}, %TradingSession{status: :open}] = result
    end
  end
end
