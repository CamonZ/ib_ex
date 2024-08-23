defmodule IbEx.Client.Messages.MarketDepth.L2DataSingleTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.L2DataSingle
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "creates the message for inserting an ask" do
      assert {:ok, msg} = L2DataSingle.from_fields(["3", "90001", "1", "0", "0", "10.5", "100"])

      assert msg.request_id == "90001"
      assert msg.position == 1
      assert msg.operation == "insert"
      assert msg.side == "ask"
      assert msg.price == 10.5
      assert msg.size == 100

      assert match?(%DateTime{}, msg.timestamp)
    end

    test "creates the message for inserting a bid" do
      assert {:ok, msg} = L2DataSingle.from_fields(["3", "90001", "1", "0", "1", "10.5", "100"])

      assert msg.request_id == "90001"
      assert msg.position == 1
      assert msg.operation == "insert"
      assert msg.side == "bid"
      assert msg.price == 10.5
      assert msg.size == 100

      assert match?(%DateTime{}, msg.timestamp)
    end

    test "creates the message for updating an ask" do
      assert {:ok, msg} = L2DataSingle.from_fields(["3", "90001", "1", "1", "0", "10.5", "100"])

      assert msg.request_id == "90001"
      assert msg.position == 1
      assert msg.operation == "update"
      assert msg.side == "ask"
      assert msg.price == 10.5
      assert msg.size == 100

      assert match?(%DateTime{}, msg.timestamp)
    end

    test "creates the message for updating a bid" do
      assert {:ok, msg} = L2DataSingle.from_fields(["3", "90001", "1", "1", "1", "10.5", "100"])

      assert msg.request_id == "90001"
      assert msg.position == 1
      assert msg.operation == "update"
      assert msg.side == "bid"
      assert msg.price == 10.5
      assert msg.size == 100

      assert match?(%DateTime{}, msg.timestamp)
    end

    test "creates the message for deleting an ask" do
      assert {:ok, msg} = L2DataSingle.from_fields(["3", "90001", "1", "2", "0", "10.5", "100"])

      assert msg.request_id == "90001"
      assert msg.position == 1
      assert msg.operation == "delete"
      assert msg.side == "ask"
      assert msg.price == 10.5
      assert msg.size == 100

      assert match?(%DateTime{}, msg.timestamp)
    end

    test "creates the message for deleting a bid" do
      {:ok, msg} = L2DataSingle.from_fields(["3", "90001", "1", "2", "1", "10.5", "100"])

      assert msg.request_id == "90001"
      assert msg.position == 1
      assert msg.operation == "delete"
      assert msg.side == "bid"
      assert msg.price == 10.5
      assert msg.size == 100

      assert match?(%DateTime{}, msg.timestamp)
    end

    test "returns an error with invalid fields" do
      assert {:error, :invalid_args} == L2DataSingle.from_fields(["invalid"])
    end
  end

  describe "Inspect implementation" do
    test "inspects L2DataSingle struct correctly" do
      timestamp = DateTime.utc_now()

      msg = %L2DataSingle{
        request_id: "90001",
        position: 1,
        operation: "insert",
        side: "ask",
        price: 10.5,
        size: 100,
        timestamp: timestamp
      }

      assert inspect(msg) ==
               """
               <-- %MarketDepth.L2DataSingle{
                 request_id: 90001,
                 position: 1,
                 operation: insert,
                 side: ask,
                 price: 10.5,
                 size: 100,
                 timestamp: #{timestamp}
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      {:ok, msg} = L2DataSingle.from_fields(["3", "1", "1", "0", "0", "10.5", "100"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
