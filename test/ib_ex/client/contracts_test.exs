defmodule IbEx.Client.ContractsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.Contracts
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

  # Wire format helpers matching the protobuf offset convention (msg_id + 200)
  @contract_data_wire_id 210
  @contract_data_end_wire_id 252
  @symbol_samples_wire_id 279
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  describe "request_details/3" do
    test "accumulates multiple ContractData responses and returns {:ok, list} on ContractDataEnd" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          Contracts.request_details(client, contract, timeout: 5_000)
        end)

      # Allow the request to register in ETS
      Process.sleep(50)

      # Inject two ContractData responses
      contract_data_1 = %Proto.ContractData{
        req_id: 1,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK"},
        contract_details: %Proto.ContractDetails{market_name: "NMS", long_name: "APPLE INC"}
      }

      Client.process_message(client, wire_message(@contract_data_wire_id, contract_data_1))

      contract_data_2 = %Proto.ContractData{
        req_id: 1,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK"},
        contract_details: %Proto.ContractDetails{market_name: "LSE", long_name: "APPLE INC - LSE"}
      }

      Client.process_message(client, wire_message(@contract_data_wire_id, contract_data_2))

      # Inject end marker
      end_marker = %Proto.ContractDataEnd{req_id: 1}
      Client.process_message(client, wire_message(@contract_data_end_wire_id, end_marker))

      # Await the result
      assert {:ok, results} = Task.await(task, 5_000)

      assert length(results) == 2

      [first, second] = results
      assert %Proto.ContractData{req_id: 1} = first
      assert first.contract_details.long_name == "APPLE INC"
      assert first.contract_details.market_name == "NMS"

      assert %Proto.ContractData{req_id: 1} = second
      assert second.contract_details.long_name == "APPLE INC - LSE"
      assert second.contract_details.market_name == "LSE"
    end

    test "returns {:error, error} when TWS sends targeted ErrorMessage for the req_id" do
      client = start_client()

      contract = %DomainContract{symbol: "INVALID", security_type: "STK", currency: "USD"}

      task =
        Task.async(fn ->
          Contracts.request_details(client, contract, timeout: 5_000)
        end)

      Process.sleep(50)

      # Inject an error message targeting req_id=1
      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      contract = %DomainContract{symbol: "AAPL", security_type: "STK", currency: "USD"}

      result =
        try do
          Contracts.request_details(client, contract, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "matching_symbols/3" do
    test "sends MatchingSymbolsRequest and returns {:ok, %SymbolSamples{}} on response" do
      client = start_client()

      task =
        Task.async(fn ->
          Contracts.matching_symbols(client, "AAPL", timeout: 5_000)
        end)

      Process.sleep(50)

      # Build a SymbolSamples response with contract descriptions
      aapl_description = %Proto.ContractDescription{
        contract: %Proto.Contract{con_id: 265_598, symbol: "AAPL", sec_type: "STK", currency: "USD"},
        derivative_sec_types: ["OPT", "WAR", "IOPT"]
      }

      msft_description = %Proto.ContractDescription{
        contract: %Proto.Contract{con_id: 272_093, symbol: "AAPLM", sec_type: "STK", currency: "USD"},
        derivative_sec_types: []
      }

      response = %Proto.SymbolSamples{
        req_id: 1,
        contract_descriptions: [aapl_description, msft_description]
      }

      Client.process_message(client, wire_message(@symbol_samples_wire_id, response))

      assert {:ok, %Proto.SymbolSamples{} = samples} = Task.await(task, 5_000)
      assert samples.req_id == 1
      assert length(samples.contract_descriptions) == 2

      [first_desc, second_desc] = samples.contract_descriptions
      assert first_desc.contract.symbol == "AAPL"
      assert first_desc.contract.con_id == 265_598
      assert first_desc.derivative_sec_types == ["OPT", "WAR", "IOPT"]

      assert second_desc.contract.symbol == "AAPLM"
      assert second_desc.derivative_sec_types == []
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          Contracts.matching_symbols(client, "INVALID_PATTERN", timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No matching symbols found"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.code == 200
      assert error.message == "No matching symbols found"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Contracts.matching_symbols(client, "AAPL", timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end
end
