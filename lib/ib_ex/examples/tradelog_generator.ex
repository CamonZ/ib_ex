defmodule IbEx.Examples.TradelogGenerator do
  use GenServer

  alias IbEx.Client
  alias IbEx.Client.Messages.Executions
  alias IbEx.Client.Messages.Executions.ExecutionData
  alias IbEx.Client.Messages.Executions.CommissionReport
  alias IbEx.Client.Messages.Executions.ExecutionDataEnd
  alias IbEx.Client.Messages.MatchingSymbols

  alias IbEx.Examples.TradelogGenerator.Transaction

  defstruct output_path: nil,
            execution_data_messages: [],
            commission_report_messages: %{},
            transactions: [],
            client_pid: nil,
            contracts_to_fetch: [],
            contract_names: %{}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :output_path, "./")
    client_pid = Keyword.get(opts, :client_pid, nil)

    continuation =
      if is_nil(client_pid) do
        {:continue, :start_client}
      else
        {:continue, :fetch_executions}
      end

    {:ok, %__MODULE__{output_path: path, client_pid: client_pid}, continuation}
  end

  @impl true
  def handle_continue(:start_client, state) do
    case Client.start_link() do
      {:ok, pid} ->
        # giving the client process 2 seconds to finish
        # stablishing the API connection according to the comm
        # protocol
        Process.send_after(self(), :fetch_executions, 2000)
        {:noreply, %{state | client_pid: pid}}

      _ ->
        {:stop, "client_connection_error", state}
    end
  end

  @impl true
  def handle_continue(:fetch_executions, state) do
    {:ok, msg} = Executions.Request.new()

    Client.send_request(state.client_pid, msg)

    {:noreply, state}
  end

  @impl true
  def handle_continue(:build_transactions, state) do
    transactions =
      state.execution_data_messages
      |> Enum.reverse()
      |> Enum.group_by(& &1.contract.symbol)
      |> Enum.map(fn item -> process_group(item, state.commission_report_messages) end)
      |> Enum.into(%{})

    contracts_to_fetch = Map.keys(transactions) |> Enum.sort()
    contract_names = Enum.reduce(contracts_to_fetch, %{}, fn symbol, acc -> Map.put(acc, symbol, "") end)

    new_state = %{
      state
      | transactions: transactions,
        contracts_to_fetch: contracts_to_fetch,
        contract_names: contract_names
    }

    {:noreply, new_state, {:continue, :fetch_contracts}}
  end

  @impl true
  def handle_continue(:fetch_contracts, state) do
    case state.contracts_to_fetch do
      [first | contracts_to_fetch] ->
        {:ok, request} = MatchingSymbols.Request.new(first)
        Client.send_request(state.client_pid, request)

        {:noreply, %{state | contracts_to_fetch: contracts_to_fetch}}

      [] ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_continue(:update_txns_with_contract, state) do
    transactions =
      Enum.reduce(state.transactions, %{}, fn {symbol, transactions}, acc ->
        updated_txns =
          Enum.map(transactions, fn txn ->
            %{txn | symbol_name: state.contract_names[symbol]}
          end)

        Map.put(acc, symbol, updated_txns)
      end)

    {:noreply, %{state | transactions: transactions}, {:continue, :write_file}}
  end

  @impl true
  def handle_continue(:write_file, state) do
    path = Path.join(state.output_path, "trades_#{Date.to_iso8601(Date.utc_today(), :basic)}.tlg")
    {:ok, f} = File.open(path, [:write])

    IO.puts(f, "ACCOUNT_INFORMATION")
    IO.puts(f, "ACT_INF||||\n\n")

    IO.puts(f, "STOCK_TRANSACTIONS")

    state.transactions
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.each(fn {_symbol, transactions} ->
      transactions
      |> Enum.reverse()
      |> Enum.each(fn txn ->
        IO.puts(
          f,
          "#{txn.type}|#{txn.id}|#{txn.symbol}|#{txn.symbol_name}|#{txn.exchange}|#{txn.full_side}|#{txn.side}|#{Date.to_iso8601(txn.date, :basic)}|#{Time.to_iso8601(txn.time)}|#{txn.currency}|#{txn.quantity}|1.00|#{txn.price}|#{txn.subtotal}|#{txn.commission}|"
        )
      end)
    end)

    IO.puts(f, "\n\n\nEOF")
    File.close(f)

    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:message_received, %ExecutionData{} = msg}, state) do
    {:noreply, %{state | execution_data_messages: [msg | state.execution_data_messages]}}
  end

  @impl true
  def handle_cast({:message_received, %CommissionReport{} = msg}, state) do
    {:noreply, %{state | commission_report_messages: Map.put(state.commission_report_messages, msg.execution_id, msg)}}
  end

  @impl true
  def handle_cast({:message_received, %ExecutionDataEnd{}}, state) do
    {:noreply, state, {:continue, :build_transactions}}
  end

  @impl true
  def handle_cast({:message_received, %MatchingSymbols.SymbolSamples{contracts: contracts}}, state) do
    contract = List.first(contracts).contract

    new_contracts =
      if Map.has_key?(state.contract_names, contract.symbol) do
        Map.put(state.contract_names, contract.symbol, contract.description)
      else
        state.contract_names
      end

    new_state = %{state | contract_names: new_contracts}

    cond do
      Enum.all?(new_contracts, fn {_k, v} -> v != "" end) ->
        {:noreply, new_state, {:continue, :update_txns_with_contract}}

      not Enum.empty?(state.contracts_to_fetch) ->
        {:noreply, new_state, {:continue, :fetch_contracts}}

      true ->
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(:fetch_executions, state) do
    {:noreply, state, {:continue, :fetch_executions}}
  end

  defp process_group({symbol, execution_messages}, commission_messages) do
    group_transactions =
      execution_messages
      |> Enum.map(fn msg -> {msg, commission_messages[msg.execution.execution_id]} end)
      |> Enum.reduce({[], 0}, fn {exec_msg, comm_msg}, {transactions, carry} ->
        transaction = Transaction.new(exec_msg, comm_msg, carry)
        {[transaction | transactions], carry + transaction.quantity}
      end)
      |> elem(0)

    {symbol, group_transactions}
  end
end
