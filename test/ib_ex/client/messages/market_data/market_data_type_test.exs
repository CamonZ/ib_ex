defmodule IbEx.Client.Messages.MarketData.MarketDataTypeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.MarketDataType
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "from_fields/1" do
    test "creates the message with valid fields for live data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", 9001, "1"])

      assert msg.request_id == 9001
      assert msg.data_type == :live
    end

    test "creates the message with valid fields for frozen data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", 9001, "2"])

      assert msg.request_id == 9001
      assert msg.data_type == :frozen
    end

    test "creates the message with valid fields for delayed data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", 9001, "3"])

      assert msg.request_id == 9001
      assert msg.data_type == :delayed
    end

    test "creates the message with valid fields for delayed_frozen data" do
      assert {:ok, msg} = MarketDataType.from_fields(["", 9001, "4"])

      assert msg.request_id == 9001
      assert msg.data_type == :delayed_frozen
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == MarketDataType.from_fields(["123", "1"])
    end
  end

  describe "maps market data type atoms to integers and vice versa" do
    test "atom_to_integer/1" do
      assert MarketDataType.atom_to_integer(:live) == 1
      assert MarketDataType.atom_to_integer(:frozen) == 2
      assert MarketDataType.atom_to_integer(:delayed) == 3
      assert MarketDataType.atom_to_integer(:delayed_frozen) == 4
    end

    test "integer_to_atom/1" do
      assert MarketDataType.integer_to_atom(1) == :live
      assert MarketDataType.integer_to_atom(2) == :frozen
      assert MarketDataType.integer_to_atom(3) == :delayed
      assert MarketDataType.integer_to_atom(4) == :delayed_frozen
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %MarketDataType{request_id: 9001, data_type: :live}
      assert Traceable.to_s(msg) == "<-- %MarketData.MarketDataType{request_id: 9001, data_type: live}"
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      request_id = Subscriptions.subscribe_by_request_id(table_ref, self())
      {:ok, msg} = MarketDataType.from_fields(["", to_string(request_id), "1"])

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
