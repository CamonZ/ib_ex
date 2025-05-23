defmodule IbEx.Client.Messages.Executions.ExecutionDataEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Executions.ExecutionDataEnd
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "creates an ExecutionDataEnd with valid fields" do
      assert {:ok, msg} = ExecutionDataEnd.from_fields(["3", "123"])

      assert msg.version == 3
      assert msg.request_id == "123"
    end

    test "returns an error with invalid number of fields" do
      assert {:error, :invalid_args} == ExecutionDataEnd.from_fields(["3"])
    end

    test "returns an error with non-list input" do
      assert {:error, :invalid_args} == ExecutionDataEnd.from_fields(nil)
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %ExecutionDataEnd{version: 3, request_id: "123"}

      assert Traceable.to_s(msg) ==
               """
               <-- ExecutionDataEnd{version: 3, request_id: 123}
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      {:ok, msg} = ExecutionDataEnd.from_fields(["3", "1"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
