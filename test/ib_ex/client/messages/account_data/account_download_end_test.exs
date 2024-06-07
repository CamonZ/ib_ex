defmodule IbEx.Client.Messages.AccountData.AccountDownloadEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.AccountData.AccountDownloadEnd
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "successfully parses a valid list into an AccountDownloadEnd struct" do
      assert {:ok, %AccountDownloadEnd{} = msg} = AccountDownloadEnd.from_fields(["2", "MYACCT123"])
      assert msg.version == 2
      assert msg.account == "MYACCT123"
    end

    test "returns an error tuple for invalid version input" do
      assert {:error, :invalid_args} = AccountDownloadEnd.from_fields(["abc", "MYACCT123"])
    end

    test "returns error for incorrect number of arguments" do
      assert {:error, :invalid_args} = AccountDownloadEnd.from_fields(["2"])
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = AccountDownloadEnd.from_fields(["3", "ACCT456"])
      assert inspect(msg) == "<-- AccountDownloadEnd{account: ACCT456}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_modules(table_ref, [AccountDownloadEnd], self())

      {:ok, msg} = AccountDownloadEnd.from_fields(["2", "MYACCT123"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
