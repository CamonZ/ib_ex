defmodule IbEx.Client.Types.ContractDetailsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.ContractDetails

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
  end
end
