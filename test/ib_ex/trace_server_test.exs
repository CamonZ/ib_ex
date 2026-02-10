defmodule IbEx.TraceServerTest do
  use ExUnit.Case, async: true

  alias IbEx.TraceServer

  defmodule FakeMsg do
    defstruct [:req_id, :order_id, :data]
  end

  defmodule OtherMsg do
    defstruct [:req_id, :value]
  end

  setup do
    {:ok, pid} = TraceServer.start_link(name: nil)
    %{server: pid}
  end

  describe "trace and messages" do
    test "stores and retrieves messages", %{server: server} do
      msg = %FakeMsg{req_id: 1, order_id: nil, data: "hello"}
      TraceServer.trace(msg, server)

      # Allow async cast to process
      entries = TraceServer.messages([], server)
      assert length(entries) == 1

      entry = hd(entries)
      assert entry.message == msg
      assert entry.type == FakeMsg
      assert entry.req_id == 1
      assert entry.order_id == nil
      assert %DateTime{} = entry.timestamp
    end

    test "stores multiple messages in order", %{server: server} do
      TraceServer.trace(%FakeMsg{req_id: 1, data: "first"}, server)
      TraceServer.trace(%FakeMsg{req_id: 2, data: "second"}, server)

      entries = TraceServer.messages([], server)
      assert length(entries) == 2
      assert hd(entries).message.data == "first"
      assert List.last(entries).message.data == "second"
    end
  end

  describe "bounded buffer eviction" do
    test "evicts oldest entries when max_size is reached" do
      {:ok, server} = TraceServer.start_link(name: nil, max_size: 3)

      TraceServer.trace(%FakeMsg{req_id: 1, data: "a"}, server)
      TraceServer.trace(%FakeMsg{req_id: 2, data: "b"}, server)
      TraceServer.trace(%FakeMsg{req_id: 3, data: "c"}, server)
      TraceServer.trace(%FakeMsg{req_id: 4, data: "d"}, server)

      assert TraceServer.count(server) == 3

      entries = TraceServer.messages([], server)
      data = Enum.map(entries, & &1.message.data)
      assert data == ["b", "c", "d"]
    end
  end

  describe "filtering" do
    test "filters by req_id", %{server: server} do
      TraceServer.trace(%FakeMsg{req_id: 1, data: "a"}, server)
      TraceServer.trace(%FakeMsg{req_id: 2, data: "b"}, server)
      TraceServer.trace(%FakeMsg{req_id: 1, data: "c"}, server)

      entries = TraceServer.messages([req_id: 1], server)
      assert length(entries) == 2
      assert Enum.all?(entries, &(&1.req_id == 1))
    end

    test "filters by order_id", %{server: server} do
      TraceServer.trace(%FakeMsg{order_id: 10, data: "a"}, server)
      TraceServer.trace(%FakeMsg{order_id: 20, data: "b"}, server)

      entries = TraceServer.messages([order_id: 10], server)
      assert length(entries) == 1
      assert hd(entries).order_id == 10
    end

    test "filters by type", %{server: server} do
      TraceServer.trace(%FakeMsg{req_id: 1, data: "a"}, server)
      TraceServer.trace(%OtherMsg{req_id: 2, value: "b"}, server)

      entries = TraceServer.messages([type: FakeMsg], server)
      assert length(entries) == 1
      assert hd(entries).type == FakeMsg
    end

    test "combines multiple filters", %{server: server} do
      TraceServer.trace(%FakeMsg{req_id: 1, data: "match"}, server)
      TraceServer.trace(%FakeMsg{req_id: 2, data: "no match"}, server)
      TraceServer.trace(%OtherMsg{req_id: 1, value: "wrong type"}, server)

      entries = TraceServer.messages([req_id: 1, type: FakeMsg], server)
      assert length(entries) == 1
      assert hd(entries).message.data == "match"
    end
  end

  describe "count" do
    test "returns zero for empty buffer", %{server: server} do
      assert TraceServer.count(server) == 0
    end

    test "returns the number of stored entries", %{server: server} do
      TraceServer.trace(%FakeMsg{data: "a"}, server)
      TraceServer.trace(%FakeMsg{data: "b"}, server)

      assert TraceServer.count(server) == 2
    end
  end

  describe "clear" do
    test "resets the buffer", %{server: server} do
      TraceServer.trace(%FakeMsg{data: "a"}, server)
      TraceServer.trace(%FakeMsg{data: "b"}, server)

      assert TraceServer.count(server) == 2

      assert :ok = TraceServer.clear(server)
      assert TraceServer.count(server) == 0
      assert TraceServer.messages([], server) == []
    end
  end
end
