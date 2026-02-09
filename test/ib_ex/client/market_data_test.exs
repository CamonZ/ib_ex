defmodule IbEx.Client.MarketDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.MarketData
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.Contract, as: DomainContract

  defmodule MockConnection do
    @moduledoc false
    use GenServer

    def start_link(opts) do
      client = Keyword.fetch!(opts, :client)
      GenServer.start_link(__MODULE__, %{client: client})
    end

    def send_message(_pid, _msg), do: :ok

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call(_, _, state), do: {:reply, :ok, state}
  end

  # Wire format helpers: raw wire_id = msg_id + @protobuf_offset (200)
  @tick_price_wire_id 201
  @tick_size_wire_id 202
  @tick_snapshot_end_wire_id 257
  @tick_by_tick_data_wire_id 299
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  describe "subscribe/3" do
    test "subscribes to market data and receives TickPrice messages" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.subscribe(client, contract)
      assert is_reference(ref)

      # Inject a TickPrice message targeting req_id=1
      tick_price = %Proto.TickPrice{req_id: 1, tick_type: 1, price: 150.25, size: "100", attr_mask: 0}
      Client.process_message(client, wire_message(@tick_price_wire_id, tick_price))

      assert_receive {:ib_ex, ^ref, %Proto.TickPrice{} = received}, 1_000
      assert received.req_id == 1
      assert received.tick_type == 1
      assert received.price == 150.25
      assert received.size == "100"
    end

    test "subscribes to market data and receives TickSize messages" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.subscribe(client, contract)

      tick_size = %Proto.TickSize{req_id: 1, tick_type: 0, size: "500"}
      Client.process_message(client, wire_message(@tick_size_wire_id, tick_size))

      assert_receive {:ib_ex, ^ref, %Proto.TickSize{} = received}, 1_000
      assert received.req_id == 1
      assert received.tick_type == 0
      assert received.size == "500"
    end

    test "accepts proto contracts directly" do
      client = start_client()
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.subscribe(client, proto_contract)
      assert is_reference(ref)

      tick_price = %Proto.TickPrice{req_id: 1, tick_type: 2, price: 151.00}
      Client.process_message(client, wire_message(@tick_price_wire_id, tick_price))

      assert_receive {:ib_ex, ^ref, %Proto.TickPrice{price: 151.00}}, 1_000
    end

    test "receives error messages for the subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.subscribe(client, contract)

      error_proto = %Proto.ErrorMessage{id: 1, error_code: 200, error_msg: "No security definition found"}
      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition found"
    end
  end

  describe "snapshot/3" do
    test "subscribes with snapshot flag and receives ticks followed by TickSnapshotEnd" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.snapshot(client, contract)
      assert is_reference(ref)

      # Inject tick data
      tick_price = %Proto.TickPrice{req_id: 1, tick_type: 1, price: 150.25, size: "100"}
      Client.process_message(client, wire_message(@tick_price_wire_id, tick_price))

      assert_receive {:ib_ex, ^ref, %Proto.TickPrice{price: 150.25}}, 1_000

      tick_size = %Proto.TickSize{req_id: 1, tick_type: 0, size: "200"}
      Client.process_message(client, wire_message(@tick_size_wire_id, tick_size))

      assert_receive {:ib_ex, ^ref, %Proto.TickSize{size: "200"}}, 1_000

      # Inject snapshot end marker
      snapshot_end = %Proto.TickSnapshotEnd{req_id: 1}
      Client.process_message(client, wire_message(@tick_snapshot_end_wire_id, snapshot_end))

      assert_receive {:ib_ex, ^ref, %Proto.TickSnapshotEnd{req_id: 1}}, 1_000
    end

    test "accepts proto contracts directly" do
      client = start_client()
      proto_contract = %Proto.Contract{symbol: "MSFT", sec_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.snapshot(client, proto_contract)
      assert is_reference(ref)
    end
  end

  describe "unsubscribe/2" do
    test "cancels an active market data subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.subscribe(client, contract)
      assert :ok = MarketData.unsubscribe(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = MarketData.unsubscribe(client, fake_ref)
    end
  end

  describe "tick_by_tick_subscribe/3" do
    test "subscribes to tick-by-tick data and receives TickByTickData messages" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.tick_by_tick_subscribe(client, contract, tick_type: "Last")
      assert is_reference(ref)

      tick_last = %Proto.HistoricalTickLast{time: 1_700_000_000, price: 150.50, size: "1"}

      tick_data = %Proto.TickByTickData{
        req_id: 1,
        tick_type: 1,
        tick: {:historical_tick_last, tick_last}
      }

      Client.process_message(client, wire_message(@tick_by_tick_data_wire_id, tick_data))

      assert_receive {:ib_ex, ^ref, %Proto.TickByTickData{} = received}, 1_000
      assert received.req_id == 1
      assert received.tick_type == 1
      assert {:historical_tick_last, last} = received.tick
      assert last.price == 150.50
      assert last.size == "1"
    end

    test "accepts proto contracts directly" do
      client = start_client()
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.tick_by_tick_subscribe(client, proto_contract, tick_type: "BidAsk")
      assert is_reference(ref)
    end

    test "receives error messages for the subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.tick_by_tick_subscribe(client, contract)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 321,
        error_msg: "Error validating request: Tick-by-tick data is not available"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.code == 321
      assert error.message == "Error validating request: Tick-by-tick data is not available"
    end
  end

  describe "tick_by_tick_unsubscribe/2" do
    test "cancels an active tick-by-tick subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketData.tick_by_tick_subscribe(client, contract)
      assert :ok = MarketData.tick_by_tick_unsubscribe(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = MarketData.tick_by_tick_unsubscribe(client, fake_ref)
    end
  end
end
