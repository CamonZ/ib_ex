defmodule IbEx.Client.ScannerTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.Scanner
  alias IbEx.Client.Proto.Protobuf, as: Proto

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
  @scanner_data_wire_id 220
  @scanner_parameters_wire_id 219
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
    test "subscribes to scanner data and receives ScannerData messages" do
      client = start_client()

      scanner_sub = %Proto.ScannerSubscription{
        instrument: "STK",
        location_code: "STK.US.MAJOR",
        scan_code: "TOP_PERC_GAIN",
        number_of_rows: 10
      }

      {:ok, ref} = Scanner.subscribe(client, scanner_sub)
      assert is_reference(ref)

      element = %Proto.ScannerDataElement{
        rank: 0,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        market_name: "NMS",
        distance: "",
        benchmark: "",
        projection: "",
        combo_key: ""
      }

      scanner_data = %Proto.ScannerData{req_id: 1, scanner_data_element: [element]}
      Client.process_message(client, wire_message(@scanner_data_wire_id, scanner_data))

      assert_receive {:ib_ex, ^ref, %Proto.ScannerData{} = received}, 1_000
      assert received.req_id == 1
      assert length(received.scanner_data_element) == 1

      [first] = received.scanner_data_element
      assert first.rank == 0
      assert first.contract.symbol == "AAPL"
      assert first.contract.sec_type == "STK"
      assert first.contract.currency == "USD"
      assert first.market_name == "NMS"
    end

    test "receives multiple ScannerData messages on the same subscription" do
      client = start_client()

      scanner_sub = %Proto.ScannerSubscription{
        instrument: "STK",
        location_code: "STK.US.MAJOR",
        scan_code: "TOP_PERC_GAIN",
        number_of_rows: 5
      }

      {:ok, ref} = Scanner.subscribe(client, scanner_sub)

      element_1 = %Proto.ScannerDataElement{
        rank: 0,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        market_name: "NMS"
      }

      element_2 = %Proto.ScannerDataElement{
        rank: 0,
        contract: %Proto.Contract{symbol: "TSLA", sec_type: "STK", currency: "USD"},
        market_name: "NMS"
      }

      data_1 = %Proto.ScannerData{req_id: 1, scanner_data_element: [element_1]}
      data_2 = %Proto.ScannerData{req_id: 1, scanner_data_element: [element_2]}

      Client.process_message(client, wire_message(@scanner_data_wire_id, data_1))
      Client.process_message(client, wire_message(@scanner_data_wire_id, data_2))

      assert_receive {:ib_ex, ^ref, %Proto.ScannerData{scanner_data_element: [e1]}}, 1_000
      assert e1.contract.symbol == "AAPL"

      assert_receive {:ib_ex, ^ref, %Proto.ScannerData{scanner_data_element: [e2]}}, 1_000
      assert e2.contract.symbol == "TSLA"
    end

    test "receives error messages for the subscription" do
      client = start_client()

      scanner_sub = %Proto.ScannerSubscription{
        instrument: "INVALID",
        location_code: "INVALID",
        scan_code: "INVALID"
      }

      {:ok, ref} = Scanner.subscribe(client, scanner_sub)

      error_proto = %Proto.ErrorMessage{id: 1, error_code: 200, error_msg: "No scanner subscription found"}
      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No scanner subscription found"
    end
  end

  describe "unsubscribe/2" do
    test "cancels an active scanner subscription" do
      client = start_client()

      scanner_sub = %Proto.ScannerSubscription{
        instrument: "STK",
        location_code: "STK.US.MAJOR",
        scan_code: "TOP_PERC_GAIN",
        number_of_rows: 10
      }

      {:ok, ref} = Scanner.subscribe(client, scanner_sub)
      assert :ok = Scanner.unsubscribe(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = Scanner.unsubscribe(client, fake_ref)
    end
  end

  describe "parameters/2" do
    test "sends ScannerParametersRequest and returns {:ok, %ScannerParameters{}}" do
      client = start_client()

      task =
        Task.async(fn ->
          Scanner.parameters(client, timeout: 5_000)
        end)

      Process.sleep(50)

      xml_content =
        "<ScanParameterResponse><InstrumentList><Instrument>STK</Instrument></InstrumentList></ScanParameterResponse>"

      response = %Proto.ScannerParameters{xml: xml_content}
      Client.process_message(client, wire_message(@scanner_parameters_wire_id, response))

      assert {:ok, %Proto.ScannerParameters{} = result} = Task.await(task, 5_000)
      assert result.xml == xml_content
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Scanner.parameters(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end
end
