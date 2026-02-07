defmodule IbEx.Client.Messages.Executions.ExecutionDataEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Executions.ExecutionDataEnd
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %ExecutionDataEnd{request_id: "123"}

      assert Traceable.to_s(msg) ==
               """
               <-- ExecutionDataEnd{request_id: 123}
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      msg = %ExecutionDataEnd{request_id: "1"}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
