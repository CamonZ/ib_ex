defmodule IbEx.Client.Messages.MatchingSymbols.SymbolSamplesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.Contract.DeltaNeutral
  alias IbEx.Client.Messages.MatchingSymbols.SymbolSamples
  alias IbEx.Client.Types.Contract
  alias IbEx.Client.Types.ContractDescription

  @valid_fields [
    "1",
    "17",
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
    "",
    "493546048",
    "AAPL",
    "STK",
    "LSEETF",
    "GBP",
    "0",
    "LS 1X AAPL",
    ""
  ]

  describe "from_fields/1" do
    test "returns the parsed message with a list of contracts" do
      assert {:ok, %SymbolSamples{contracts: contracts} = samples} = SymbolSamples.from_fields(@valid_fields)

      assert samples.request_id == "1"

      assert contracts == [
               %ContractDescription{
                 contract: %Contract{
                   conid: "265598",
                   symbol: "AAPL",
                   security_type: "STK",
                   currency: "USD",
                   primary_exchange: "NASDAQ",
                   description: "APPLE INC",
                   issuer_id: "",
                   delta_neutral_contract: DeltaNeutral.new()
                 },
                 derivative_security_types: ["CFD", "OPT", "IOPT", "WAR", "BAG"]
               },
               %ContractDescription{
                 contract: %Contract{
                   conid: "493546048",
                   symbol: "AAPL",
                   security_type: "STK",
                   currency: "GBP",
                   primary_exchange: "LSEETF",
                   description: "LS 1X AAPL",
                   issuer_id: "",
                   delta_neutral_contract: DeltaNeutral.new()
                 },
                 derivative_security_types: []
               }
             ]
    end

    test "returns invalid args when called with something other than a list" do
      assert {:error, :invalid_args} == SymbolSamples.from_fields(%{})
    end

    @tag capture_log: true
    test "returns invalid args when called with a list in a different format" do
      assert {:error, :invalid_args} == SymbolSamples.from_fields(["1", "2", "3"])
    end
  end
end
