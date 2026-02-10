defmodule IbEx.Client.Types.TradingSessionTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.TradingSession

  describe "parse/1 with CLOSED entries" do
    test "parses a CLOSED entry into a closed session" do
      assert {:ok, session} = TradingSession.parse("20260208:CLOSED")

      assert session.date == ~D[2026-02-08]
      assert session.status == :closed
      assert session.open == nil
      assert session.close == nil
    end

    test "parses a different CLOSED date" do
      assert {:ok, session} = TradingSession.parse("20260101:CLOSED")

      assert session.date == ~D[2026-01-01]
      assert session.status == :closed
    end
  end

  describe "parse/1 with time-range entries" do
    test "parses a time-range entry into an open session" do
      assert {:ok, session} = TradingSession.parse("20260209:0400-20260209:2000")

      assert session.date == ~D[2026-02-09]
      assert session.status == :open
      assert session.open == ~T[04:00:00]
      assert session.close == ~T[20:00:00]
    end

    test "parses a session with midnight boundaries" do
      assert {:ok, session} = TradingSession.parse("20260210:0000-20260210:2359")

      assert session.date == ~D[2026-02-10]
      assert session.status == :open
      assert session.open == ~T[00:00:00]
      assert session.close == ~T[23:59:00]
    end

    test "parses a session spanning different dates" do
      assert {:ok, session} = TradingSession.parse("20260209:1700-20260210:1700")

      assert session.date == ~D[2026-02-09]
      assert session.status == :open
      assert session.open == ~T[17:00:00]
      assert session.close == ~T[17:00:00]
    end
  end

  describe "parse/1 with invalid input" do
    test "returns error for empty string" do
      assert {:error, :invalid_format} = TradingSession.parse("")
    end

    test "returns error for arbitrary string" do
      assert {:error, :invalid_format} = TradingSession.parse("not-a-session")
    end

    test "returns error for non-binary input" do
      assert {:error, :invalid_format} = TradingSession.parse(123)
    end

    test "returns error for nil input" do
      assert {:error, :invalid_format} = TradingSession.parse(nil)
    end

    test "returns error for malformed date in CLOSED entry" do
      assert {:error, _} = TradingSession.parse("99999999:CLOSED")
    end

    test "returns error for malformed time in range entry" do
      assert {:error, _} = TradingSession.parse("20260209:9999-20260209:2000")
    end
  end
end
