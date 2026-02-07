defmodule IbEx.Client.Types.MarketDepthDescriptionTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.MarketDepthDescription

  describe "from_market_depth_exchanges/1" do
    test "creates a MarketDepthDescription with valid fields" do
      assert {:ok, description} =
               MarketDepthDescription.from_market_depth_exchanges(["NYSE", "STK", "NSDQ", "DataType1", "1"])

      assert description.exchange == "NYSE"
      assert description.security_type == "STK"
      assert description.listing_exchange == "NSDQ"
      assert description.service_data_type == "DataType1"
      assert description.aggregate_group == "1"
    end

    test "returns an error with invalid fields" do
      assert {:error, :invalid_args} == MarketDepthDescription.from_market_depth_exchanges(["NYSE"])
    end
  end
end
