defmodule IbEx.Client.Types.HistoricalSessionTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.HistoricalSession

  describe "new/0" do
    test "creates a HistoricalSession struct with default attributes" do
      assert HistoricalSession.new() == %HistoricalSession{
               start_date_time: nil,
               end_date_time: nil,
               ref_date: nil
             }
    end
  end

  describe "new/1" do
    test "creates a HistoricalSession struct from a map" do
      params = %{
        start_date_time: "20250115 09:30:00",
        end_date_time: "20250115 16:00:00",
        ref_date: "20250115"
      }

      result = HistoricalSession.new(params)

      assert result.start_date_time == "20250115 09:30:00"
      assert result.end_date_time == "20250115 16:00:00"
      assert result.ref_date == "20250115"
    end

    test "creates a HistoricalSession struct from a keyword list" do
      params = [
        start_date_time: "20250115 09:30:00",
        end_date_time: "20250115 16:00:00"
      ]

      result = HistoricalSession.new(params)

      assert result.start_date_time == "20250115 09:30:00"
      assert result.end_date_time == "20250115 16:00:00"
      assert result.ref_date == nil
    end
  end
end
