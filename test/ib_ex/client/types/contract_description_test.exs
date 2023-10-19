defmodule IbEx.Client.Types.ContractDescriptionTest do
  use ExUnit.Case

  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.ContractDescription

  @valid_fields [
    "265598",
    "AAPL",
    "STK",
    "NASDAQ",
    "USD",
    "5",
    "CFD",
    "OPT",
    "IOPT",
    "WAR",
    "BAG",
    "APPLE INC",
    ""
  ]

  describe "from_fields/1" do
    test "returns the contract description" do
      assert {:ok, %ContractDescription{contract: contract, derivative_security_types: derivatives}} =
               ContractDescription.from_fields(@valid_fields)

      assert contract == %Contract{
               conid: "265598",
               symbol: "AAPL",
               security_type: "STK",
               currency: "USD",
               primary_exchange: "NASDAQ",
               description: "APPLE INC",
               issuer_id: ""
             }

      assert derivatives == ["CFD", "OPT", "IOPT", "WAR", "BAG"]
    end

    test "returns invalid args when called with something other than a list" do
      assert {:error, :invalid_args} == ContractDescription.from_fields(%{})
    end

    test "returns invalid args when called with a list in a different format" do
      assert {:error, :invalid_args} == ContractDescription.from_fields(["1", "2", "3"])
    end
  end
end
