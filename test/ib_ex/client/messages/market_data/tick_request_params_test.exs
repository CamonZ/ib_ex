defmodule IbEx.Client.Messages.MarketData.TickRequestParamsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickRequestParams

  describe "from_fields/1" do
    test "creates TickRequestParams struct with valid fields" do
      assert {:ok, msg} = TickRequestParams.from_fields(["90001", "0.01", "9c0001", "3"])

      assert msg.request_id == "90001"
      assert msg.min_tick == 0.01
      assert msg.bbo_exchange == "9c0001"
      assert msg.snapshot_permissions == 3
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == TickRequestParams.from_fields(["123", "0.01", "NASDAQ"])
    end
  end

  describe "Inspect implementation" do
    test "inspects TickRequestParams struct correctly" do
      msg = %TickRequestParams{
        request_id: "9001",
        min_tick: 0.01,
        bbo_exchange: "9c0001",
        snapshot_permissions: 1
      }

      assert inspect(msg) ==
               "<-- %MarketData.TickRequestParams{request_id: 9001, min_tick: 0.01, bbo_exchange: 9c0001, snapshot_permissions: 1}"
    end
  end
end
