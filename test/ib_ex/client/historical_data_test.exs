defmodule IbEx.Client.HistoricalDataTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.HistoricalData
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
  @historical_data_wire_id 217
  @historical_data_end_wire_id 308
  @head_timestamp_wire_id 288
  @histogram_data_wire_id 289
  @historical_ticks_wire_id 296
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  describe "request_bars/3" do
    test "accumulates HistoricalData responses and returns {:ok, list} on HistoricalDataEnd" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.request_bars(client, contract, timeout: 5_000)
        end)

      Process.sleep(50)

      bar_1 = %Proto.HistoricalDataBar{date: "20240101", open: 150.0, high: 155.0, low: 149.0, close: 154.0}
      bar_2 = %Proto.HistoricalDataBar{date: "20240102", open: 154.0, high: 158.0, low: 153.0, close: 157.0}

      historical_data = %Proto.HistoricalData{
        req_id: 1,
        historical_data_bars: [bar_1, bar_2]
      }

      Client.process_message(client, wire_message(@historical_data_wire_id, historical_data))

      end_marker = %Proto.HistoricalDataEnd{req_id: 1, start_date_str: "20240101", end_date_str: "20240102"}
      Client.process_message(client, wire_message(@historical_data_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 1

      [first] = results
      assert %Proto.HistoricalData{req_id: 1} = first
      assert length(first.historical_data_bars) == 2

      [returned_bar_1, returned_bar_2] = first.historical_data_bars
      assert returned_bar_1.date == "20240101"
      assert returned_bar_1.open == 150.0
      assert returned_bar_1.close == 154.0

      assert returned_bar_2.date == "20240102"
      assert returned_bar_2.open == 154.0
      assert returned_bar_2.close == 157.0
    end

    test "accepts proto contracts directly" do
      client = start_client()

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.request_bars(client, proto_contract, timeout: 5_000)
        end)

      Process.sleep(50)

      historical_data = %Proto.HistoricalData{
        req_id: 1,
        historical_data_bars: [%Proto.HistoricalDataBar{date: "20240101", open: 150.0, close: 154.0}]
      }

      Client.process_message(client, wire_message(@historical_data_wire_id, historical_data))

      end_marker = %Proto.HistoricalDataEnd{req_id: 1}
      Client.process_message(client, wire_message(@historical_data_end_wire_id, end_marker))

      assert {:ok, [%Proto.HistoricalData{req_id: 1}]} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.request_bars(client, contract, timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 162,
        error_msg: "Historical Market Data Service error message:No data of type TRADES"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.id == 1
      assert error.code == 162
      assert error.message == "Historical Market Data Service error message:No data of type TRADES"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      result =
        try do
          HistoricalData.request_bars(client, contract, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "head_timestamp/3" do
    test "sends HeadTimestampRequest and returns {:ok, %HeadTimestamp{}} on response" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.head_timestamp(client, contract, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.HeadTimestamp{
        req_id: 1,
        head_timestamp: "1083297600"
      }

      Client.process_message(client, wire_message(@head_timestamp_wire_id, response))

      assert {:ok, %Proto.HeadTimestamp{} = result} = Task.await(task, 5_000)
      assert result.req_id == 1
      assert result.head_timestamp == "1083297600"
    end

    test "accepts proto contracts directly" do
      client = start_client()

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.head_timestamp(client, proto_contract, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.HeadTimestamp{req_id: 1, head_timestamp: "1083297600"}
      Client.process_message(client, wire_message(@head_timestamp_wire_id, response))

      assert {:ok, %Proto.HeadTimestamp{head_timestamp: "1083297600"}} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.head_timestamp(client, contract, timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      result =
        try do
          HistoricalData.head_timestamp(client, contract, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "histogram/3" do
    test "sends HistogramDataRequest and returns {:ok, %HistogramData{}} on response" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.histogram(client, contract, timeout: 5_000)
        end)

      Process.sleep(50)

      entry_1 = %Proto.HistogramDataEntry{price: 150.0, size: "1000"}
      entry_2 = %Proto.HistogramDataEntry{price: 151.5, size: "2500"}

      response = %Proto.HistogramData{
        req_id: 1,
        histogram_data_entries: [entry_1, entry_2]
      }

      Client.process_message(client, wire_message(@histogram_data_wire_id, response))

      assert {:ok, %Proto.HistogramData{} = result} = Task.await(task, 5_000)
      assert result.req_id == 1
      assert length(result.histogram_data_entries) == 2

      [first_entry, second_entry] = result.histogram_data_entries
      assert first_entry.price == 150.0
      assert first_entry.size == "1000"
      assert second_entry.price == 151.5
      assert second_entry.size == "2500"
    end

    test "accepts proto contracts directly" do
      client = start_client()

      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.histogram(client, proto_contract, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.HistogramData{
        req_id: 1,
        histogram_data_entries: [%Proto.HistogramDataEntry{price: 150.0, size: "1000"}]
      }

      Client.process_message(client, wire_message(@histogram_data_wire_id, response))

      assert {:ok, %Proto.HistogramData{req_id: 1}} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          HistoricalData.histogram(client, contract, timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      result =
        try do
          HistoricalData.histogram(client, contract, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "request_ticks/3" do
    test "subscribes to historical ticks and receives HistoricalTicks messages" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = HistoricalData.request_ticks(client, contract)
      assert is_reference(ref)

      tick_1 = %Proto.HistoricalTick{time: 1_700_000_000, price: 150.25, size: "100"}
      tick_2 = %Proto.HistoricalTick{time: 1_700_000_001, price: 150.50, size: "200"}

      response = %Proto.HistoricalTicks{
        req_id: 1,
        historical_ticks: [tick_1, tick_2],
        is_done: false
      }

      Client.process_message(client, wire_message(@historical_ticks_wire_id, response))

      assert_receive {:ib_ex, ^ref, %Proto.HistoricalTicks{} = received}, 1_000
      assert received.req_id == 1
      assert length(received.historical_ticks) == 2
      assert received.is_done == false
    end

    test "receives final batch with is_done flag set to true" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = HistoricalData.request_ticks(client, contract)

      response = %Proto.HistoricalTicks{
        req_id: 1,
        historical_ticks: [%Proto.HistoricalTick{time: 1_700_000_000, price: 150.25, size: "100"}],
        is_done: true
      }

      Client.process_message(client, wire_message(@historical_ticks_wire_id, response))

      assert_receive {:ib_ex, ^ref, %Proto.HistoricalTicks{is_done: true}}, 1_000
    end

    test "accepts proto contracts directly" do
      client = start_client()
      proto_contract = %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"}

      {:ok, ref} = HistoricalData.request_ticks(client, proto_contract)
      assert is_reference(ref)
    end

    test "receives error messages for the subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      {:ok, ref} = HistoricalData.request_ticks(client, contract)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end
  end

  describe "unsubscribe_ticks/2" do
    test "cancels an active historical ticks subscription" do
      client = start_client()
      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      {:ok, ref} = HistoricalData.request_ticks(client, contract)
      assert :ok = HistoricalData.unsubscribe_ticks(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = HistoricalData.unsubscribe_ticks(client, fake_ref)
    end
  end
end
