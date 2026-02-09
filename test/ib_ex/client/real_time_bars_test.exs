defmodule IbEx.Client.RealTimeBarsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.RealTimeBars
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
  @real_time_bar_tick_wire_id 250
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
    test "subscribes to real-time bars and receives RealTimeBarTick messages" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = RealTimeBars.subscribe(client, contract)
      assert is_reference(ref)

      tick = %Proto.RealTimeBarTick{
        req_id: 1,
        time: 1_705_312_200,
        open: 150.25,
        high: 151.00,
        low: 149.50,
        close: 150.75,
        volume: "500",
        wap: "150.50",
        count: 25
      }

      Client.process_message(client, wire_message(@real_time_bar_tick_wire_id, tick))

      assert_receive {:ib_ex, ^ref, %Proto.RealTimeBarTick{} = received}, 1_000
      assert received.req_id == 1
      assert received.time == 1_705_312_200
      assert received.open == 150.25
      assert received.high == 151.00
      assert received.low == 149.50
      assert received.close == 150.75
      assert received.volume == "500"
      assert received.wap == "150.50"
      assert received.count == 25
    end

    test "receives multiple RealTimeBarTick messages on the same subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = RealTimeBars.subscribe(client, contract)

      tick_1 = %Proto.RealTimeBarTick{
        req_id: 1,
        time: 1_705_312_200,
        open: 150.25,
        high: 151.00,
        low: 149.50,
        close: 150.75,
        volume: "500",
        wap: "150.50",
        count: 25
      }

      tick_2 = %Proto.RealTimeBarTick{
        req_id: 1,
        time: 1_705_312_205,
        open: 150.75,
        high: 152.00,
        low: 150.50,
        close: 151.50,
        volume: "750",
        wap: "151.25",
        count: 30
      }

      Client.process_message(client, wire_message(@real_time_bar_tick_wire_id, tick_1))
      Client.process_message(client, wire_message(@real_time_bar_tick_wire_id, tick_2))

      assert_receive {:ib_ex, ^ref, %Proto.RealTimeBarTick{time: 1_705_312_200}}, 1_000
      assert_receive {:ib_ex, ^ref, %Proto.RealTimeBarTick{time: 1_705_312_205, close: 151.50}}, 1_000
    end

    test "accepts proto contracts directly" do
      client = start_client()
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      {:ok, ref} = RealTimeBars.subscribe(client, proto_contract)
      assert is_reference(ref)

      tick = %Proto.RealTimeBarTick{req_id: 1, time: 1_705_312_200, open: 150.25, close: 150.75}
      Client.process_message(client, wire_message(@real_time_bar_tick_wire_id, tick))

      assert_receive {:ib_ex, ^ref, %Proto.RealTimeBarTick{open: 150.25, close: 150.75}}, 1_000
    end

    test "receives error messages for the subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      {:ok, ref} = RealTimeBars.subscribe(client, contract)

      error_proto = %Proto.ErrorMessage{id: 1, error_code: 200, error_msg: "No security definition found"}
      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition found"
    end
  end

  describe "unsubscribe/2" do
    test "cancels an active real-time bars subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = RealTimeBars.subscribe(client, contract)
      assert :ok = RealTimeBars.unsubscribe(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = RealTimeBars.unsubscribe(client, fake_ref)
    end
  end
end
