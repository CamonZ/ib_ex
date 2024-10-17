defmodule IbEx.Client.Types.ContractTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Contract

  describe "new/1" do
    test "creates a Contract with valid attributes" do
      attrs = %{conid: "520512263", symbol: "GTLB", security_type: "STK"}

      assert Contract.new(attrs) == %Contract{
               conid: "520512263",
               symbol: "GTLB",
               security_type: "STK",
               delta_neutral_contract: nil
             }
    end
  end

  describe "serialize/1" do
    test "serializes a Contract including expired field" do
      contract = %Contract{conid: "520512263", symbol: "GTLB", security_type: "STK", include_expired: true}

      assert Contract.serialize(contract) == [
               "520512263",
               "GTLB",
               "STK",
               "",
               "0.0",
               "",
               "",
               "SMART",
               "",
               "",
               "",
               "",
               true
             ]
    end

    test "serializes a Contract without including expired field" do
      contract = %Contract{conid: "520512263", symbol: "GTLB", security_type: "STK", include_expired: false}

      assert Contract.serialize(contract, false) == [
               "520512263",
               "GTLB",
               "STK",
               "",
               "0.0",
               "",
               "",
               "SMART",
               "",
               "",
               "",
               ""
             ]
    end
  end

  describe "from_serialized_fields/1" do
    test "creates a Contract with valid serialized fields" do
      assert {:ok, contract} =
               Contract.from_serialized_fields([
                 "520512263",
                 "GTLB",
                 "STK",
                 "",
                 "0.0",
                 "",
                 "",
                 "ISLAND",
                 "USD",
                 "GTLB",
                 ""
               ])

      assert contract == %Contract{
               conid: "520512263",
               symbol: "GTLB",
               security_type: "STK",
               last_trade_date_or_contract_month: "",
               strike: "0.0",
               right: "",
               multiplier: "",
               exchange: "ISLAND",
               currency: "USD",
               local_symbol: "GTLB",
               trading_class: "",
               delta_neutral_contract: nil
             }
    end

    test "returns an error with invalid number of fields" do
      assert {:error, :invalid_args} == Contract.from_serialized_fields(["520512263", "GTLB"])
    end

    test "returns an error with non-list input" do
      assert {:error, :invalid_args} == Contract.from_serialized_fields(nil)
    end
  end

  describe "rights/0" do
    test "returns the different types of rights a contract can have" do
      assert Contract.rights() == ["C", "CALL", "P", "PUT", "?"]
    end
  end

  describe "security_types/0" do
    test "returns the different types of security_types a contract can have" do
      assert Contract.security_types() == [
               "STK",
               "OPT",
               "FUT",
               "IND",
               "FOP",
               "CASH",
               "BAG",
               "WAR",
               "BOND",
               "CMDTY",
               "NEWS",
               "FUND"
             ]
    end
  end
end
