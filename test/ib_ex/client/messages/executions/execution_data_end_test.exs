defmodule IbEx.Client.Messages.Executions.ExecutionDataEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Executions.ExecutionDataEnd

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

  describe "inspect/2" do
    test "returns a human-readable version of the message" do
      msg = %ExecutionDataEnd{version: 3, request_id: "123"}

      assert inspect(msg) ==
               """
               <-- ExecutionDataEnd{version: 3, request_id: 123}
               """
    end
  end
end
