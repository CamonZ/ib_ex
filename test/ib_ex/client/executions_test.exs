defmodule IbEx.Client.ExecutionsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.Executions
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.ExecutionsFilter, as: DomainFilter

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
  @execution_details_wire_id 211
  @execution_details_end_wire_id 255
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  describe "request/3 without filter" do
    test "accumulates ExecutionDetails responses and returns {:ok, list} on ExecutionDetailsEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Executions.request(client, nil, timeout: 5_000)
        end)

      Process.sleep(50)

      exec_1 = %Proto.ExecutionDetails{
        req_id: 1,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        execution: %Proto.Execution{
          exec_id: "0001",
          order_id: 10,
          side: "BUY",
          shares: "100",
          price: 150.25,
          time: "20240115 10:30:00"
        }
      }

      exec_2 = %Proto.ExecutionDetails{
        req_id: 1,
        contract: %Proto.Contract{symbol: "MSFT", sec_type: "STK", currency: "USD"},
        execution: %Proto.Execution{
          exec_id: "0002",
          order_id: 11,
          side: "SELL",
          shares: "50",
          price: 380.50,
          time: "20240115 11:00:00"
        }
      }

      Client.process_message(client, wire_message(@execution_details_wire_id, exec_1))
      Client.process_message(client, wire_message(@execution_details_wire_id, exec_2))

      end_marker = %Proto.ExecutionDetailsEnd{req_id: 1}
      Client.process_message(client, wire_message(@execution_details_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.ExecutionDetails{req_id: 1} = first
      assert first.contract.symbol == "AAPL"
      assert first.execution.exec_id == "0001"
      assert first.execution.side == "BUY"
      assert first.execution.shares == "100"
      assert first.execution.price == 150.25
      assert first.execution.time == "20240115 10:30:00"

      assert %Proto.ExecutionDetails{req_id: 1} = second
      assert second.contract.symbol == "MSFT"
      assert second.execution.exec_id == "0002"
      assert second.execution.side == "SELL"
      assert second.execution.shares == "50"
      assert second.execution.price == 380.50
    end

    test "returns {:ok, []} when no executions exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Executions.request(client, nil, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.ExecutionDetailsEnd{req_id: 1}
      Client.process_message(client, wire_message(@execution_details_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          Executions.request(client, nil, timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 321,
        error_msg: "Error validating request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.id == 1
      assert error.code == 321
      assert error.message == "Error validating request"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Executions.request(client, nil, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "request/3 with proto filter" do
    test "sends ExecutionRequest with proto ExecutionFilter and returns accumulated results" do
      client = start_client()

      proto_filter = %Proto.ExecutionFilter{symbol: "AAPL", side: "BUY"}

      task =
        Task.async(fn ->
          Executions.request(client, proto_filter, timeout: 5_000)
        end)

      Process.sleep(50)

      exec = %Proto.ExecutionDetails{
        req_id: 1,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        execution: %Proto.Execution{
          exec_id: "0001",
          order_id: 10,
          side: "BUY",
          shares: "100",
          price: 150.25
        }
      }

      Client.process_message(client, wire_message(@execution_details_wire_id, exec))

      end_marker = %Proto.ExecutionDetailsEnd{req_id: 1}
      Client.process_message(client, wire_message(@execution_details_end_wire_id, end_marker))

      assert {:ok, [%Proto.ExecutionDetails{} = result]} = Task.await(task, 5_000)
      assert result.req_id == 1
      assert result.contract.symbol == "AAPL"
      assert result.execution.side == "BUY"
      assert result.execution.shares == "100"
      assert result.execution.price == 150.25
    end
  end

  describe "request/3 with domain filter" do
    test "converts domain ExecutionsFilter to proto and returns accumulated results" do
      client = start_client()

      {:ok, domain_filter} = DomainFilter.new(symbol: "AAPL", side: "BUY")

      task =
        Task.async(fn ->
          Executions.request(client, domain_filter, timeout: 5_000)
        end)

      Process.sleep(50)

      exec = %Proto.ExecutionDetails{
        req_id: 1,
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        execution: %Proto.Execution{
          exec_id: "0003",
          order_id: 12,
          side: "BUY",
          shares: "200",
          price: 152.00
        }
      }

      Client.process_message(client, wire_message(@execution_details_wire_id, exec))

      end_marker = %Proto.ExecutionDetailsEnd{req_id: 1}
      Client.process_message(client, wire_message(@execution_details_end_wire_id, end_marker))

      assert {:ok, [%Proto.ExecutionDetails{} = result]} = Task.await(task, 5_000)
      assert result.req_id == 1
      assert result.contract.symbol == "AAPL"
      assert result.execution.exec_id == "0003"
      assert result.execution.side == "BUY"
      assert result.execution.shares == "200"
      assert result.execution.price == 152.00
    end
  end

  describe "request/3 default arguments" do
    test "request/1 with only client pid uses no filter" do
      client = start_client()

      task =
        Task.async(fn ->
          Executions.request(client)
        end)

      Process.sleep(50)

      end_marker = %Proto.ExecutionDetailsEnd{req_id: 1}
      Client.process_message(client, wire_message(@execution_details_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end
  end
end
