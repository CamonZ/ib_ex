defmodule IbEx.Client.Messages.AccountData.AccountDetailTest do
  use ExUnit.Case, async: true
  alias IbEx.Client.Messages.AccountData.AccountDetail

  describe "from_fields/1" do
    test "successfully parses a valid list into an AccountDetail struct" do
      assert {:ok, %AccountDetail{} = msg} = AccountDetail.from_fields(["1", "NetLiquidation", "100000", "USD", "MYACCT123"])
      assert msg.version == 1
      assert msg.field == "NetLiquidation"
      assert msg.value == "100000"
      assert msg.currency == "USD"
      assert msg.account == "MYACCT123"
    end

    test "returns an error tuple for invalid input" do
      assert {:error, :invalid_args} = AccountDetail.from_fields(["abc", "NetLiquidation", "100000", "USD", "MYACCT123"])
    end

    test "returns error for incorrect number of arguments" do
      assert {:error, :invalid_args} = AccountDetail.from_fields(["1", "NetLiquidation"])
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = AccountDetail.from_fields(["1", "EquityWithLoanValue", "50000", "EUR", "ACCT456"])
      assert inspect(msg) == "<-- AccountDetail{field: EquityWithLoanValue, value: 50000, currency: EUR, account: ACCT456}"
    end
  end
end
