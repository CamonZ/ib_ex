defmodule IbEx.Client.Messages.AccountData.AccountDetailTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.AccountData.AccountDetail

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %AccountDetail{field: "NetLiquidation", value: "100000", currency: "USD", account: "MYACCT123"}

      assert Traceable.to_s(msg) ==
               "<-- AccountDetail{field: NetLiquidation, value: 100000, currency: USD, account: MYACCT123}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_modules(table_ref, [AccountDetail], self())

      msg = %AccountDetail{field: "NetLiquidation", value: "100000", currency: "USD", account: "MYACCT123"}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
