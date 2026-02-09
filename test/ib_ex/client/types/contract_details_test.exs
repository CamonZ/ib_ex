defmodule IbEx.Client.Types.ContractDetailsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.ContractDetails
  alias IbEx.Client.Types.TradingSession

  describe "new/1 valid_exchanges parsing" do
    test "parses comma-separated valid_exchanges string into a list of strings" do
      details = ContractDetails.new(%{valid_exchanges: "SMART,AMEX,NYSE"})

      assert details.valid_exchanges == ["SMART", "AMEX", "NYSE"]
    end

    test "returns empty list when valid_exchanges is nil" do
      details = ContractDetails.new(%{valid_exchanges: nil})

      assert details.valid_exchanges == []
    end

    test "returns empty list when valid_exchanges is an empty string" do
      details = ContractDetails.new(%{valid_exchanges: ""})

      assert details.valid_exchanges == []
    end

    test "preserves an already-parsed list for valid_exchanges" do
      details = ContractDetails.new(%{valid_exchanges: ["SMART", "AMEX"]})

      assert details.valid_exchanges == ["SMART", "AMEX"]
    end

    test "returns empty list when valid_exchanges is not provided" do
      details = ContractDetails.new(%{})

      assert details.valid_exchanges == []
    end
  end

  describe "new/1 order_types parsing" do
    test "parses comma-separated order_types string into a list of strings" do
      details = ContractDetails.new(%{order_types: "ACTIVETIM,AUC,COND"})

      assert details.order_types == ["ACTIVETIM", "AUC", "COND"]
    end

    test "returns empty list when order_types is nil" do
      details = ContractDetails.new(%{order_types: nil})

      assert details.order_types == []
    end

    test "returns empty list when order_types is an empty string" do
      details = ContractDetails.new(%{order_types: ""})

      assert details.order_types == []
    end

    test "preserves an already-parsed list for order_types" do
      details = ContractDetails.new(%{order_types: ["ACTIVETIM", "AUC"]})

      assert details.order_types == ["ACTIVETIM", "AUC"]
    end

    test "returns empty list when order_types is not provided" do
      details = ContractDetails.new(%{})

      assert details.order_types == []
    end
  end

  describe "new/1 with keyword list" do
    test "parses valid_exchanges and order_types from keyword list attrs" do
      details = ContractDetails.new(valid_exchanges: "SMART,AMEX", order_types: "MKT,LMT")

      assert details.valid_exchanges == ["SMART", "AMEX"]
      assert details.order_types == ["MKT", "LMT"]
    end
  end

  describe "new/0" do
    test "creates a ContractDetails with default empty lists for valid_exchanges and order_types" do
      details = ContractDetails.new()

      assert details.valid_exchanges == []
      assert details.order_types == []
    end

    test "creates a ContractDetails struct with empty lists for trading_hours and liquid_hours" do
      result = ContractDetails.new()

      assert result.trading_hours == []
      assert result.liquid_hours == []
    end
  end

  describe "new/1 parses trading_hours and liquid_hours" do
    test "parses trading_hours string into list of TradingSession structs" do
      attrs = %{
        trading_hours: "20260208:CLOSED;20260209:0400-20260209:2000"
      }

      result = ContractDetails.new(attrs)

      assert length(result.trading_hours) == 2

      assert [closed_session, open_session] = result.trading_hours
      assert %TradingSession{date: ~D[2026-02-08], status: :closed, open: nil, close: nil} = closed_session

      assert %TradingSession{date: ~D[2026-02-09], status: :open, open: ~T[04:00:00], close: ~T[20:00:00]} =
               open_session
    end

    test "parses liquid_hours string into list of TradingSession structs" do
      attrs = %{
        liquid_hours: "20260208:CLOSED;20260209:0930-20260209:1600"
      }

      result = ContractDetails.new(attrs)

      assert length(result.liquid_hours) == 2

      assert [closed_session, open_session] = result.liquid_hours
      assert %TradingSession{date: ~D[2026-02-08], status: :closed} = closed_session

      assert %TradingSession{date: ~D[2026-02-09], status: :open, open: ~T[09:30:00], close: ~T[16:00:00]} =
               open_session
    end

    test "parses both trading_hours and liquid_hours from keyword list" do
      attrs = [
        trading_hours: "20260209:0400-20260209:2000",
        liquid_hours: "20260209:0930-20260209:1600"
      ]

      result = ContractDetails.new(attrs)

      assert [%TradingSession{status: :open, open: ~T[04:00:00], close: ~T[20:00:00]}] = result.trading_hours
      assert [%TradingSession{status: :open, open: ~T[09:30:00], close: ~T[16:00:00]}] = result.liquid_hours
    end

    test "leaves trading_hours as empty list when not provided" do
      result = ContractDetails.new(%{market_name: "NMS"})

      assert result.trading_hours == []
      assert result.liquid_hours == []
    end

    test "preserves already-parsed list of TradingSession structs" do
      sessions = [%TradingSession{date: ~D[2026-02-09], status: :open, open: ~T[04:00:00], close: ~T[20:00:00]}]
      attrs = %{trading_hours: sessions}

      result = ContractDetails.new(attrs)

      assert result.trading_hours == sessions
    end
  end
end
