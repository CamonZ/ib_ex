defmodule IbEx.Client.Messages.AccountData.AccountUpdateTimeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.AccountData.AccountUpdateTime
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      {:ok, ts} = NaiveDateTime.new(Date.utc_today(), ~T[10:47:00])
      msg = %AccountUpdateTime{timestamp: ts}

      expected_output = "<-- AccountUpdateTime{timestamp: #{ts}}"
      assert Traceable.to_s(msg) == expected_output
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_modules(table_ref, [AccountUpdateTime], self())

      msg = %AccountUpdateTime{timestamp: ~N[2024-01-01 10:47:00]}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
