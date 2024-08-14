defmodule IbEx.Client.Messages.MarketData.TickSizeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickSize
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "creates TickSize struct with valid fields" do
      assert {:ok, msg} = TickSize.from_fields(["", "123", "0", "200"])

      assert msg.request_id == "123"
      assert msg.tick_type == :bid_size
      assert msg.size == Decimal.new("200")
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == TickSize.from_fields(["123", "1"])
    end
  end

  describe "Inspect implementation" do
    test "inspects TickSize struct correctly" do
      msg = %TickSize{
        request_id: "123",
        tick_type: :bid_size,
        size: Decimal.new("200")
      }

      assert inspect(msg) ==
               "<-- %MarketData.TickSize{request_id: 123, tick_type: bid_size, size: 200}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      {:ok, msg} = TickSize.from_fields(["", "1", "0", "200"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
