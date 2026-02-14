defmodule IbEx.Client.ContractResolverTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.ContractResolver
  alias IbEx.Client.Proto.Protobuf, as: Proto
  alias IbEx.Client.Types.ContractDetails

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

  defmodule RecordingConnection do
    @moduledoc """
    Connection mock that records sent messages to an ETS table so the test process
    can retrieve them. The table key is the Client GenServer pid.
    """
    use GenServer

    def start_link(opts) do
      client = Keyword.fetch!(opts, :client)
      GenServer.start_link(__MODULE__, %{client: client})
    end

    def send_message(pid, msg) do
      GenServer.call(pid, {:send_message, msg})
    end

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call({:send_message, msg}, _from, state) do
      # Look up the test pid from the shared ETS table
      case :ets.lookup(:contract_resolver_test_pids, state.client) do
        [{_, test_pid}] -> send(test_pid, {:tws_sent, msg})
        [] -> :ok
      end

      {:reply, :ok, state}
    end
  end

  @contract_data_wire_id 210
  @contract_data_end_wire_id 252
  @error_message_wire_id 204

  setup_all do
    :ets.new(:contract_resolver_test_pids, [:named_table, :public, :set])
    :ok
  end

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client(connection_handler \\ MockConnection) do
    {:ok, pid} = Client.start_link(connection_handler: connection_handler)
    pid
  end

  defp start_recording_client do
    pid = start_client(RecordingConnection)
    :ets.insert(:contract_resolver_test_pids, {pid, self()})

    on_exit(fn ->
      :ets.delete(:contract_resolver_test_pids, pid)
    end)

    pid
  end

  defp start_resolver(client) do
    {:ok, pid} = ContractResolver.start_link(client: client)
    pid
  end

  defp inject_contract_data(client, req_id, contracts) do
    for contract_data <- contracts do
      Client.process_message(client, wire_message(@contract_data_wire_id, %{contract_data | req_id: req_id}))
    end

    end_marker = %Proto.ContractDataEnd{req_id: req_id}
    Client.process_message(client, wire_message(@contract_data_end_wire_id, end_marker))
  end

  defp inject_error(client, req_id, code, message) do
    error = %Proto.ErrorMessage{id: req_id, error_code: code, error_msg: message}
    Client.process_message(client, wire_message(@error_message_wire_id, error))
  end

  # ---------------------------------------------------------------------------
  # build_contract shorthand translation (tested indirectly via resolve)
  # ---------------------------------------------------------------------------

  describe "resolve/3 with stock shorthand" do
    test "resolves {:stock, symbol} with USD currency and SMART exchange defaults" do
      client = start_recording_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000)
        end)

      Process.sleep(50)

      # Verify the request was sent to TWS with correct contract fields
      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)
      assert decoded_request.contract.symbol == "AAPL"
      assert decoded_request.contract.sec_type == "STK"
      assert decoded_request.contract.currency == "USD"
      assert decoded_request.contract.exchange == "SMART"

      # Inject response
      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{con_id: 265_598, symbol: "AAPL", sec_type: "STK", currency: "USD"},
        contract_details: %Proto.ContractDetails{long_name: "APPLE INC", market_name: "NMS"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, [%ContractDetails{} = result]} = Task.await(task, 5_000)
      assert result.contract.symbol == "AAPL"
      assert result.contract.conid == "265598"
      assert result.long_name == "APPLE INC"
    end

    test "resolves {:stock, symbol, currency} with explicit currency" do
      client = start_recording_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:stock, "SAP", "EUR"}, timeout: 5_000)
        end)

      Process.sleep(50)

      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)
      assert decoded_request.contract.symbol == "SAP"
      assert decoded_request.contract.sec_type == "STK"
      assert decoded_request.contract.currency == "EUR"
      assert decoded_request.contract.exchange == "SMART"

      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{con_id: 100_001, symbol: "SAP", sec_type: "STK", currency: "EUR"},
        contract_details: %Proto.ContractDetails{long_name: "SAP SE"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, [%ContractDetails{} = result]} = Task.await(task, 5_000)
      assert result.contract.symbol == "SAP"
      assert result.contract.currency == "EUR"
      assert result.long_name == "SAP SE"
    end
  end

  describe "resolve/3 with forex shorthand" do
    test "resolves {:forex, symbol, currency} as CASH on IDEALPRO" do
      client = start_recording_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:forex, "EUR", "USD"}, timeout: 5_000)
        end)

      Process.sleep(50)

      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)
      assert decoded_request.contract.symbol == "EUR"
      assert decoded_request.contract.sec_type == "CASH"
      assert decoded_request.contract.currency == "USD"
      assert decoded_request.contract.exchange == "IDEALPRO"

      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{con_id: 12_087_792, symbol: "EUR", sec_type: "CASH", currency: "USD"},
        contract_details: %Proto.ContractDetails{long_name: "European Monetary Union Euro"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, [%ContractDetails{} = result]} = Task.await(task, 5_000)
      assert result.contract.symbol == "EUR"
      assert result.contract.security_type == "CASH"
      assert result.long_name == "European Monetary Union Euro"
    end
  end

  describe "resolve/3 with future shorthand" do
    test "resolves {:future, symbol, expiry} as FUT on CME" do
      client = start_recording_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:future, "ES", "202506"}, timeout: 5_000)
        end)

      Process.sleep(50)

      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)
      assert decoded_request.contract.symbol == "ES"
      assert decoded_request.contract.sec_type == "FUT"
      assert decoded_request.contract.currency == "USD"
      assert decoded_request.contract.exchange == "CME"
      assert decoded_request.contract.last_trade_date_or_contract_month == "202506"

      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{
          con_id: 551_601_770,
          symbol: "ES",
          sec_type: "FUT",
          last_trade_date_or_contract_month: "20250620"
        },
        contract_details: %Proto.ContractDetails{long_name: "E-mini S&P 500"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, [%ContractDetails{} = result]} = Task.await(task, 5_000)
      assert result.contract.symbol == "ES"
      assert result.contract.security_type == "FUT"
      assert result.long_name == "E-mini S&P 500"
    end
  end

  describe "resolve/3 with option shorthand" do
    test "resolves {:option, symbol, expiry, strike, :call} as OPT with right C" do
      client = start_recording_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:option, "AAPL", "20260320", 200.0, :call}, timeout: 5_000)
        end)

      Process.sleep(50)

      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)
      assert decoded_request.contract.symbol == "AAPL"
      assert decoded_request.contract.sec_type == "OPT"
      assert decoded_request.contract.currency == "USD"
      assert decoded_request.contract.exchange == "SMART"
      assert decoded_request.contract.last_trade_date_or_contract_month == "20260320"
      assert decoded_request.contract.strike == 200.0
      assert decoded_request.contract.right == "C"

      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{
          con_id: 700_000_001,
          symbol: "AAPL",
          sec_type: "OPT",
          strike: 200.0,
          right: "C"
        },
        contract_details: %Proto.ContractDetails{long_name: "APPLE INC"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, [%ContractDetails{} = result]} = Task.await(task, 5_000)
      assert result.contract.symbol == "AAPL"
      assert result.contract.security_type == "OPT"
      assert result.contract.right == "C"
    end

    test "resolves {:option, symbol, expiry, strike, :put} as OPT with right P" do
      client = start_recording_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:option, "AAPL", "20260320", 200.0, :put}, timeout: 5_000)
        end)

      Process.sleep(50)

      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)
      assert decoded_request.contract.right == "P"

      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{
          con_id: 700_000_002,
          symbol: "AAPL",
          sec_type: "OPT",
          strike: 200.0,
          right: "P"
        },
        contract_details: %Proto.ContractDetails{long_name: "APPLE INC"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, [%ContractDetails{} = result]} = Task.await(task, 5_000)
      assert result.contract.right == "P"
      assert result.contract.conid == "700000002"
    end

    test "resolves options with integer strike values" do
      client = start_recording_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:option, "AAPL", "20260320", 200, :call}, timeout: 5_000)
        end)

      Process.sleep(50)

      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)
      assert decoded_request.contract.strike == 200.0

      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{con_id: 700_000_003, symbol: "AAPL", sec_type: "OPT", strike: 200.0, right: "C"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, [%ContractDetails{} = result]} = Task.await(task, 5_000)
      assert result.contract.right == "C"
    end
  end

  # ---------------------------------------------------------------------------
  # ETS caching
  # ---------------------------------------------------------------------------

  describe "caching" do
    test "second resolve for the same shorthand returns cached result without hitting TWS" do
      client = start_recording_client()
      resolver = start_resolver(client)

      # First resolve -- should hit TWS
      task1 =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000)
        end)

      Process.sleep(50)
      assert_receive {:tws_sent, sent_msg}
      <<_wire_id::big-integer-size(32), payload::binary>> = sent_msg
      decoded_request = Protobuf.decode(payload, Proto.ContractDataRequest)

      contract_data = %Proto.ContractData{
        contract: %Proto.Contract{con_id: 265_598, symbol: "AAPL", sec_type: "STK"},
        contract_details: %Proto.ContractDetails{long_name: "APPLE INC"}
      }

      inject_contract_data(client, decoded_request.req_id, [contract_data])

      assert {:ok, first_results} = Task.await(task1, 5_000)
      assert length(first_results) == 1

      # Second resolve -- should return cached, no TWS message
      assert {:ok, cached_results} = ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000)
      refute_receive {:tws_sent, _}

      assert cached_results == first_results
      assert hd(cached_results).contract.conid == "265598"
      assert hd(cached_results).long_name == "APPLE INC"
    end

    test "different shorthands are cached independently" do
      client = start_recording_client()
      resolver = start_resolver(client)

      # Resolve AAPL
      task1 = Task.async(fn -> ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000) end)
      Process.sleep(50)
      assert_receive {:tws_sent, msg1}
      <<_::big-integer-size(32), p1::binary>> = msg1
      req1 = Protobuf.decode(p1, Proto.ContractDataRequest)

      inject_contract_data(client, req1.req_id, [
        %Proto.ContractData{
          contract: %Proto.Contract{con_id: 265_598, symbol: "AAPL", sec_type: "STK"},
          contract_details: %Proto.ContractDetails{long_name: "APPLE INC"}
        }
      ])

      assert {:ok, _} = Task.await(task1, 5_000)

      # Resolve MSFT -- should still hit TWS (different shorthand)
      task2 = Task.async(fn -> ContractResolver.resolve(resolver, {:stock, "MSFT"}, timeout: 5_000) end)
      Process.sleep(50)
      assert_receive {:tws_sent, msg2}
      <<_::big-integer-size(32), p2::binary>> = msg2
      req2 = Protobuf.decode(p2, Proto.ContractDataRequest)
      assert req2.contract.symbol == "MSFT"

      inject_contract_data(client, req2.req_id, [
        %Proto.ContractData{
          contract: %Proto.Contract{con_id: 272_093, symbol: "MSFT", sec_type: "STK"},
          contract_details: %Proto.ContractDetails{long_name: "MICROSOFT CORP"}
        }
      ])

      assert {:ok, [msft]} = Task.await(task2, 5_000)
      assert msft.contract.symbol == "MSFT"

      # Both should be cached now
      assert {:ok, [aapl_cached]} = ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000)
      assert aapl_cached.contract.symbol == "AAPL"

      assert {:ok, [msft_cached]} = ContractResolver.resolve(resolver, {:stock, "MSFT"}, timeout: 5_000)
      assert msft_cached.contract.symbol == "MSFT"

      refute_receive {:tws_sent, _}
    end
  end

  describe "clear_cache/1" do
    test "flushes the cache so next resolve hits TWS again" do
      client = start_recording_client()
      resolver = start_resolver(client)

      # First resolve
      task1 = Task.async(fn -> ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000) end)
      Process.sleep(50)
      assert_receive {:tws_sent, msg1}
      <<_::big-integer-size(32), p1::binary>> = msg1
      req1 = Protobuf.decode(p1, Proto.ContractDataRequest)

      inject_contract_data(client, req1.req_id, [
        %Proto.ContractData{
          contract: %Proto.Contract{con_id: 265_598, symbol: "AAPL", sec_type: "STK"},
          contract_details: %Proto.ContractDetails{long_name: "APPLE INC"}
        }
      ])

      assert {:ok, _} = Task.await(task1, 5_000)

      # Clear cache
      assert :ok = ContractResolver.clear_cache(resolver)

      # Resolve again -- should hit TWS
      task2 = Task.async(fn -> ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000) end)
      Process.sleep(50)
      assert_receive {:tws_sent, msg2}
      <<_::big-integer-size(32), p2::binary>> = msg2
      req2 = Protobuf.decode(p2, Proto.ContractDataRequest)
      assert req2.contract.symbol == "AAPL"

      inject_contract_data(client, req2.req_id, [
        %Proto.ContractData{
          contract: %Proto.Contract{con_id: 265_598, symbol: "AAPL", sec_type: "STK"},
          contract_details: %Proto.ContractDetails{long_name: "APPLE INC - REFRESHED"}
        }
      ])

      assert {:ok, [%ContractDetails{} = refreshed]} = Task.await(task2, 5_000)
      assert refreshed.long_name == "APPLE INC - REFRESHED"
    end
  end

  # ---------------------------------------------------------------------------
  # Multiple matches (ambiguous symbols)
  # ---------------------------------------------------------------------------

  describe "multiple contract matches" do
    test "returns all matches when TWS resolves a symbol to multiple contracts" do
      client = start_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:stock, "AAPL"}, timeout: 5_000)
        end)

      Process.sleep(50)

      contract_data_1 = %Proto.ContractData{
        req_id: 1,
        contract: %Proto.Contract{con_id: 265_598, symbol: "AAPL", sec_type: "STK", exchange: "NASDAQ"},
        contract_details: %Proto.ContractDetails{long_name: "APPLE INC", market_name: "NMS"}
      }

      contract_data_2 = %Proto.ContractData{
        req_id: 1,
        contract: %Proto.Contract{con_id: 38_708_077, symbol: "AAPL", sec_type: "STK", exchange: "LSE"},
        contract_details: %Proto.ContractDetails{long_name: "APPLE INC", market_name: "LSE"}
      }

      inject_contract_data(client, 1, [contract_data_1, contract_data_2])

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert first.contract.conid == "265598"
      assert first.market_name == "NMS"
      assert second.contract.conid == "38708077"
      assert second.market_name == "LSE"
    end
  end

  # ---------------------------------------------------------------------------
  # Error handling
  # ---------------------------------------------------------------------------

  describe "error handling" do
    test "returns {:error, :invalid_shorthand} for unrecognized tuple formats" do
      client = start_client()
      resolver = start_resolver(client)

      assert {:error, :invalid_shorthand} = ContractResolver.resolve(resolver, {:unknown, "XYZ"}, timeout: 1_000)
      assert {:error, :invalid_shorthand} = ContractResolver.resolve(resolver, {:stock}, timeout: 1_000)
      assert {:error, :invalid_shorthand} = ContractResolver.resolve(resolver, "AAPL", timeout: 1_000)
    end

    test "returns {:error, error} when TWS sends an error for the request" do
      client = start_client()
      resolver = start_resolver(client)

      task =
        Task.async(fn ->
          ContractResolver.resolve(resolver, {:stock, "INVALID"}, timeout: 5_000)
        end)

      Process.sleep(50)

      inject_error(client, 1, 200, "No security definition has been found for the request")

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end

    test "errors are not cached" do
      client = start_recording_client()
      resolver = start_resolver(client)

      # First resolve -- error
      task1 = Task.async(fn -> ContractResolver.resolve(resolver, {:stock, "BAD"}, timeout: 5_000) end)
      Process.sleep(50)
      assert_receive {:tws_sent, msg1}
      <<_::big-integer-size(32), p1::binary>> = msg1
      req1 = Protobuf.decode(p1, Proto.ContractDataRequest)

      inject_error(client, req1.req_id, 200, "No security definition has been found for the request")
      assert {:error, _} = Task.await(task1, 5_000)

      # Second resolve -- should hit TWS again (error was not cached)
      task2 = Task.async(fn -> ContractResolver.resolve(resolver, {:stock, "BAD"}, timeout: 5_000) end)
      Process.sleep(50)
      assert_receive {:tws_sent, _msg2}

      # We got a new TWS request, confirming no cache
      Task.shutdown(task2)
    end
  end

  # ---------------------------------------------------------------------------
  # GenServer lifecycle
  # ---------------------------------------------------------------------------

  describe "start_link/1" do
    test "starts the resolver with a name option" do
      client = start_client()
      name = :"resolver_#{System.unique_integer([:positive])}"
      assert {:ok, pid} = ContractResolver.start_link(client: client, name: name)
      assert Process.alive?(pid)
      assert Process.whereis(name) == pid
    end

    test "requires client option" do
      Process.flag(:trap_exit, true)
      assert {:error, {%KeyError{key: :client}, _stacktrace}} = ContractResolver.start_link([])
    end
  end
end
