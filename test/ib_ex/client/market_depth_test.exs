defmodule IbEx.Client.MarketDepthTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.MarketDepth
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
  @market_depth_wire_id 212
  @market_depth_l2_wire_id 213
  @market_depth_exchanges_wire_id 280
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
    test "subscribes to market depth and receives MarketDepth messages" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketDepth.subscribe(client, contract)
      assert is_reference(ref)

      depth_data = %Proto.MarketDepthData{
        position: 0,
        operation: 0,
        side: 1,
        price: 150.25,
        size: "100"
      }

      market_depth = %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}
      Client.process_message(client, wire_message(@market_depth_wire_id, market_depth))

      assert_receive {:ib_ex, ^ref, %Proto.MarketDepth{} = received}, 1_000
      assert received.req_id == 1
      assert received.market_depth_data.position == 0
      assert received.market_depth_data.operation == 0
      assert received.market_depth_data.side == 1
      assert received.market_depth_data.price == 150.25
      assert received.market_depth_data.size == "100"
    end

    test "subscribes to market depth and receives MarketDepthL2 messages" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketDepth.subscribe(client, contract)

      depth_data = %Proto.MarketDepthData{
        position: 1,
        operation: 1,
        side: 0,
        price: 149.50,
        size: "200",
        market_maker: "ISLAND",
        is_smart_depth: true
      }

      market_depth_l2 = %Proto.MarketDepthL2{req_id: 1, market_depth_data: depth_data}
      Client.process_message(client, wire_message(@market_depth_l2_wire_id, market_depth_l2))

      assert_receive {:ib_ex, ^ref, %Proto.MarketDepthL2{} = received}, 1_000
      assert received.req_id == 1
      assert received.market_depth_data.position == 1
      assert received.market_depth_data.operation == 1
      assert received.market_depth_data.side == 0
      assert received.market_depth_data.price == 149.50
      assert received.market_depth_data.size == "200"
      assert received.market_depth_data.market_maker == "ISLAND"
      assert received.market_depth_data.is_smart_depth == true
    end

    test "accepts proto contracts directly" do
      client = start_client()
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      {:ok, ref} = MarketDepth.subscribe(client, proto_contract)
      assert is_reference(ref)

      depth_data = %Proto.MarketDepthData{position: 0, operation: 0, side: 1, price: 151.00, size: "50"}
      market_depth = %Proto.MarketDepth{req_id: 1, market_depth_data: depth_data}
      Client.process_message(client, wire_message(@market_depth_wire_id, market_depth))

      assert_receive {:ib_ex, ^ref, %Proto.MarketDepth{market_depth_data: %{price: 151.00}}}, 1_000
    end

    test "receives error messages for the subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketDepth.subscribe(client, contract)

      error_proto = %Proto.ErrorMessage{id: 1, error_code: 200, error_msg: "No security definition found"}
      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition found"
    end
  end

  describe "unsubscribe/2" do
    test "cancels an active market depth subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = MarketDepth.subscribe(client, contract)
      assert :ok = MarketDepth.unsubscribe(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = MarketDepth.unsubscribe(client, fake_ref)
    end
  end

  describe "exchanges/2" do
    test "sends MarketDepthExchangesRequest and returns {:ok, %MarketDepthExchanges{}}" do
      client = start_client()

      task =
        Task.async(fn ->
          MarketDepth.exchanges(client, timeout: 5_000)
        end)

      Process.sleep(50)

      desc_1 = %Proto.DepthMarketDataDescription{
        exchange: "ISLAND",
        sec_type: "STK",
        listing_exch: "NYSE",
        service_data_type: "Deep2",
        agg_group: 1
      }

      desc_2 = %Proto.DepthMarketDataDescription{
        exchange: "ARCA",
        sec_type: "STK",
        listing_exch: "NASDAQ",
        service_data_type: "Deep",
        agg_group: 2
      }

      response = %Proto.MarketDepthExchanges{depth_market_data_descriptions: [desc_1, desc_2]}
      Client.process_message(client, wire_message(@market_depth_exchanges_wire_id, response))

      assert {:ok, %Proto.MarketDepthExchanges{} = result} = Task.await(task, 5_000)
      assert length(result.depth_market_data_descriptions) == 2

      [first, second] = result.depth_market_data_descriptions
      assert first.exchange == "ISLAND"
      assert first.sec_type == "STK"
      assert first.listing_exch == "NYSE"
      assert first.service_data_type == "Deep2"
      assert first.agg_group == 1

      assert second.exchange == "ARCA"
      assert second.sec_type == "STK"
      assert second.listing_exch == "NASDAQ"
      assert second.service_data_type == "Deep"
      assert second.agg_group == 2
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          MarketDepth.exchanges(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end
end
