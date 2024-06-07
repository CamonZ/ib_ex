defmodule IbEx.Client.Messages.AccountData.AccountUpdateTimeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.AccountData.AccountUpdateTime
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "parses valid inputs into an AccountUpdateTime struct" do
      {:ok, msg} = AccountUpdateTime.from_fields(["1", "10:47"])
      assert msg.version == 1
      assert {:ok, msg.timestamp} == NaiveDateTime.new(Date.utc_today(), ~T[10:47:00])
    end

    test "handles edge case around midnight" do
      {:ok, msg} = AccountUpdateTime.from_fields(["1", "00:01"])
      assert {:ok, msg.timestamp} == NaiveDateTime.new(Date.utc_today(), ~T[00:01:00])
    end

    test "returns error for invalid version string" do
      assert {:error, :invalid_args} = AccountUpdateTime.from_fields(["abc", "10:47"])
    end

    test "returns error for invalid time format" do
      assert {:error, :invalid_args} = AccountUpdateTime.from_fields(["1", "24:00"])
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the struct" do
      {:ok, msg} = AccountUpdateTime.from_fields(["1", "10:47"])
      {:ok, ts} = NaiveDateTime.new(Date.utc_today(), ~T[10:47:00])

      expected_output = "<-- AccountUpdateTime{timestamp: #{ts}}"
      assert inspect(msg) == expected_output
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_modules(table_ref, [AccountUpdateTime], self())

      {:ok, msg} = AccountUpdateTime.from_fields(["1", "10:47"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
