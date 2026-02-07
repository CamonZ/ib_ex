defmodule IbEx.Client.Types.ScanDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.ScanData
  alias IbEx.Client.Types.Contract

  describe "new/0" do
    test "creates a ScanData struct with default attributes" do
      assert ScanData.new() == %ScanData{
               contract: nil,
               rank: nil,
               distance: nil,
               benchmark: nil,
               projection: nil,
               legs_str: nil
             }
    end
  end

  describe "new/1" do
    test "creates a ScanData struct from a map with all fields" do
      contract = %Contract{symbol: "AAPL", security_type: "STK"}

      params = %{
        contract: contract,
        rank: 0,
        distance: "5.2",
        benchmark: "SPX",
        projection: "1.5",
        legs_str: "BUY 1 AAPL"
      }

      result = ScanData.new(params)

      assert result.contract.symbol == "AAPL"
      assert result.contract.security_type == "STK"
      assert result.rank == 0
      assert result.distance == "5.2"
      assert result.benchmark == "SPX"
      assert result.projection == "1.5"
      assert result.legs_str == "BUY 1 AAPL"
    end

    test "creates a ScanData struct from a keyword list" do
      params = [rank: 3, distance: "2.1"]

      result = ScanData.new(params)

      assert result.rank == 3
      assert result.distance == "2.1"
      assert result.contract == nil
      assert result.benchmark == nil
    end
  end
end
