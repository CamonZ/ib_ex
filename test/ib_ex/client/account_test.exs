defmodule IbEx.Client.AccountTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.Account
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
  @account_value_wire_id 206
  @portfolio_value_wire_id 207
  @account_update_time_wire_id 208
  @account_data_end_wire_id 254
  @position_wire_id 261
  @position_end_wire_id 262
  @account_summary_wire_id 263
  @account_summary_end_wire_id 264
  @position_multi_wire_id 271
  @position_multi_end_wire_id 272
  @account_update_multi_wire_id 273
  @account_update_multi_end_wire_id 274
  @pnl_wire_id 294
  @pnl_single_wire_id 295
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  describe "request_updates/3" do
    test "accumulates AccountValue and PortfolioValue responses and returns {:ok, list} on AccountDataEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.request_updates(client, "DU123456", timeout: 5_000)
        end)

      Process.sleep(50)

      account_value = %Proto.AccountValue{
        key: "NetLiquidation",
        value: "100000.00",
        currency: "USD",
        account_name: "DU123456"
      }

      portfolio_value = %Proto.PortfolioValue{
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        position: "100",
        market_price: 150.25,
        market_value: 15025.0,
        average_cost: 145.00,
        unrealized_pnl: 525.0,
        realized_pnl: 0.0,
        account_name: "DU123456"
      }

      account_update_time = %Proto.AccountUpdateTime{time_stamp: "15:30"}

      Client.process_message(client, wire_message(@account_value_wire_id, account_value))
      Client.process_message(client, wire_message(@portfolio_value_wire_id, portfolio_value))
      Client.process_message(client, wire_message(@account_update_time_wire_id, account_update_time))

      end_marker = %Proto.AccountDataEnd{account_name: "DU123456"}
      Client.process_message(client, wire_message(@account_data_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 3

      [first, second, third] = results
      assert %Proto.AccountValue{} = first
      assert first.key == "NetLiquidation"
      assert first.value == "100000.00"
      assert first.currency == "USD"
      assert first.account_name == "DU123456"

      assert %Proto.PortfolioValue{} = second
      assert second.contract.symbol == "AAPL"
      assert second.position == "100"
      assert second.market_price == 150.25
      assert second.market_value == 15025.0
      assert second.unrealized_pnl == 525.0

      assert %Proto.AccountUpdateTime{} = third
      assert third.time_stamp == "15:30"
    end

    test "returns {:ok, []} when no account data exists" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.request_updates(client, "DU123456", timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.AccountDataEnd{account_name: "DU123456"}
      Client.process_message(client, wire_message(@account_data_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Account.request_updates(client, "DU123456", timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "positions/2" do
    test "accumulates Position responses and returns {:ok, list} on PositionEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.positions(client, timeout: 5_000)
        end)

      Process.sleep(50)

      position_1 = %Proto.Position{
        account: "DU123456",
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        position: "100",
        avg_cost: 145.00
      }

      position_2 = %Proto.Position{
        account: "DU123456",
        contract: %Proto.Contract{symbol: "MSFT", sec_type: "STK", currency: "USD"},
        position: "50",
        avg_cost: 380.00
      }

      Client.process_message(client, wire_message(@position_wire_id, position_1))
      Client.process_message(client, wire_message(@position_wire_id, position_2))

      end_marker = %Proto.PositionEnd{}
      Client.process_message(client, wire_message(@position_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.Position{} = first
      assert first.account == "DU123456"
      assert first.contract.symbol == "AAPL"
      assert first.position == "100"
      assert first.avg_cost == 145.00

      assert %Proto.Position{} = second
      assert second.contract.symbol == "MSFT"
      assert second.position == "50"
      assert second.avg_cost == 380.00
    end

    test "returns {:ok, []} when no positions exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.positions(client, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.PositionEnd{}
      Client.process_message(client, wire_message(@position_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Account.positions(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "summary/2" do
    test "accumulates AccountSummary responses and returns {:ok, list} on AccountSummaryEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.summary(client, timeout: 5_000)
        end)

      Process.sleep(50)

      summary_1 = %Proto.AccountSummary{
        req_id: 1,
        account: "DU123456",
        tag: "NetLiquidation",
        value: "100000.00",
        currency: "USD"
      }

      summary_2 = %Proto.AccountSummary{
        req_id: 1,
        account: "DU123456",
        tag: "TotalCashValue",
        value: "50000.00",
        currency: "USD"
      }

      Client.process_message(client, wire_message(@account_summary_wire_id, summary_1))
      Client.process_message(client, wire_message(@account_summary_wire_id, summary_2))

      end_marker = %Proto.AccountSummaryEnd{req_id: 1}
      Client.process_message(client, wire_message(@account_summary_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.AccountSummary{} = first
      assert first.req_id == 1
      assert first.account == "DU123456"
      assert first.tag == "NetLiquidation"
      assert first.value == "100000.00"
      assert first.currency == "USD"

      assert %Proto.AccountSummary{} = second
      assert second.tag == "TotalCashValue"
      assert second.value == "50000.00"
    end

    test "returns {:ok, []} when no summary data exists" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.summary(client, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.AccountSummaryEnd{req_id: 1}
      Client.process_message(client, wire_message(@account_summary_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.summary(client, timeout: 5_000)
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
          Account.summary(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "positions_multi/3" do
    test "accumulates PositionMulti responses and returns {:ok, list} on PositionMultiEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.positions_multi(client, "DU123456", timeout: 5_000)
        end)

      Process.sleep(50)

      position_1 = %Proto.PositionMulti{
        req_id: 1,
        account: "DU123456",
        contract: %Proto.Contract{symbol: "AAPL", sec_type: "STK", currency: "USD"},
        position: "100",
        avg_cost: 145.00,
        model_code: ""
      }

      position_2 = %Proto.PositionMulti{
        req_id: 1,
        account: "DU123456",
        contract: %Proto.Contract{symbol: "MSFT", sec_type: "STK", currency: "USD"},
        position: "50",
        avg_cost: 380.00,
        model_code: ""
      }

      Client.process_message(client, wire_message(@position_multi_wire_id, position_1))
      Client.process_message(client, wire_message(@position_multi_wire_id, position_2))

      end_marker = %Proto.PositionMultiEnd{req_id: 1}
      Client.process_message(client, wire_message(@position_multi_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.PositionMulti{} = first
      assert first.req_id == 1
      assert first.account == "DU123456"
      assert first.contract.symbol == "AAPL"
      assert first.position == "100"
      assert first.avg_cost == 145.00

      assert %Proto.PositionMulti{} = second
      assert second.contract.symbol == "MSFT"
      assert second.position == "50"
      assert second.avg_cost == 380.00
    end

    test "returns {:ok, []} when no positions exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.positions_multi(client, "DU123456", timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.PositionMultiEnd{req_id: 1}
      Client.process_message(client, wire_message(@position_multi_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.positions_multi(client, "INVALID", timeout: 5_000)
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
          Account.positions_multi(client, "DU123456", timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "updates_multi/3" do
    test "accumulates AccountUpdateMulti responses and returns {:ok, list} on AccountUpdateMultiEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.updates_multi(client, "DU123456", timeout: 5_000)
        end)

      Process.sleep(50)

      update_1 = %Proto.AccountUpdateMulti{
        req_id: 1,
        account: "DU123456",
        model_code: "",
        key: "NetLiquidation",
        value: "100000.00",
        currency: "USD"
      }

      update_2 = %Proto.AccountUpdateMulti{
        req_id: 1,
        account: "DU123456",
        model_code: "",
        key: "TotalCashValue",
        value: "50000.00",
        currency: "USD"
      }

      Client.process_message(client, wire_message(@account_update_multi_wire_id, update_1))
      Client.process_message(client, wire_message(@account_update_multi_wire_id, update_2))

      end_marker = %Proto.AccountUpdateMultiEnd{req_id: 1}
      Client.process_message(client, wire_message(@account_update_multi_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.AccountUpdateMulti{} = first
      assert first.req_id == 1
      assert first.account == "DU123456"
      assert first.key == "NetLiquidation"
      assert first.value == "100000.00"
      assert first.currency == "USD"

      assert %Proto.AccountUpdateMulti{} = second
      assert second.key == "TotalCashValue"
      assert second.value == "50000.00"
    end

    test "returns {:ok, []} when no updates exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.updates_multi(client, "DU123456", timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.AccountUpdateMultiEnd{req_id: 1}
      Client.process_message(client, wire_message(@account_update_multi_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          Account.updates_multi(client, "INVALID", timeout: 5_000)
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
          Account.updates_multi(client, "DU123456", timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "pnl/3" do
    test "subscribes to PnL updates and receives PnL messages" do
      client = start_client()

      {:ok, ref} = Account.pnl(client, "DU123456")
      assert is_reference(ref)

      pnl_response = %Proto.PnL{
        req_id: 1,
        daily_pn_l: 1250.50,
        unrealized_pn_l: 3200.00,
        realized_pn_l: 500.00
      }

      Client.process_message(client, wire_message(@pnl_wire_id, pnl_response))

      assert_receive {:ib_ex, ^ref, %Proto.PnL{} = received}, 1_000
      assert received.req_id == 1
      assert received.daily_pn_l == 1250.50
      assert received.unrealized_pn_l == 3200.00
      assert received.realized_pn_l == 500.00
    end

    test "receives multiple PnL updates on the same subscription" do
      client = start_client()

      {:ok, ref} = Account.pnl(client, "DU123456")

      pnl_1 = %Proto.PnL{req_id: 1, daily_pn_l: 1250.50, unrealized_pn_l: 3200.00, realized_pn_l: 500.00}
      pnl_2 = %Proto.PnL{req_id: 1, daily_pn_l: 1300.75, unrealized_pn_l: 3250.00, realized_pn_l: 500.00}

      Client.process_message(client, wire_message(@pnl_wire_id, pnl_1))
      Client.process_message(client, wire_message(@pnl_wire_id, pnl_2))

      assert_receive {:ib_ex, ^ref, %Proto.PnL{daily_pn_l: 1250.50}}, 1_000
      assert_receive {:ib_ex, ^ref, %Proto.PnL{daily_pn_l: 1300.75}}, 1_000
    end

    test "receives error messages for the subscription" do
      client = start_client()

      {:ok, ref} = Account.pnl(client, "INVALID")

      error_proto = %Proto.ErrorMessage{id: 1, error_code: 321, error_msg: "Error validating request"}
      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 321
      assert error.message == "Error validating request"
    end
  end

  describe "pnl_single/4" do
    test "subscribes to single-position PnL updates and receives PnLSingle messages" do
      client = start_client()

      {:ok, ref} = Account.pnl_single(client, "DU123456", 265_598)
      assert is_reference(ref)

      pnl_single_response = %Proto.PnLSingle{
        req_id: 1,
        position: "100",
        daily_pn_l: 325.50,
        unrealized_pn_l: 1200.00,
        realized_pn_l: 0.0,
        value: 15025.0
      }

      Client.process_message(client, wire_message(@pnl_single_wire_id, pnl_single_response))

      assert_receive {:ib_ex, ^ref, %Proto.PnLSingle{} = received}, 1_000
      assert received.req_id == 1
      assert received.position == "100"
      assert received.daily_pn_l == 325.50
      assert received.unrealized_pn_l == 1200.00
      assert received.realized_pn_l == 0.0
      assert received.value == 15025.0
    end

    test "receives multiple PnLSingle updates on the same subscription" do
      client = start_client()

      {:ok, ref} = Account.pnl_single(client, "DU123456", 265_598)

      pnl_1 = %Proto.PnLSingle{
        req_id: 1,
        position: "100",
        daily_pn_l: 325.50,
        unrealized_pn_l: 1200.00,
        realized_pn_l: 0.0,
        value: 15025.0
      }

      pnl_2 = %Proto.PnLSingle{
        req_id: 1,
        position: "100",
        daily_pn_l: 350.00,
        unrealized_pn_l: 1250.00,
        realized_pn_l: 0.0,
        value: 15050.0
      }

      Client.process_message(client, wire_message(@pnl_single_wire_id, pnl_1))
      Client.process_message(client, wire_message(@pnl_single_wire_id, pnl_2))

      assert_receive {:ib_ex, ^ref, %Proto.PnLSingle{daily_pn_l: 325.50}}, 1_000
      assert_receive {:ib_ex, ^ref, %Proto.PnLSingle{daily_pn_l: 350.00, value: 15050.0}}, 1_000
    end

    test "receives error messages for the subscription" do
      client = start_client()

      {:ok, ref} = Account.pnl_single(client, "INVALID", 0)

      error_proto = %Proto.ErrorMessage{id: 1, error_code: 321, error_msg: "Error validating request"}
      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 321
      assert error.message == "Error validating request"
    end
  end

  describe "unsubscribe_pnl/2" do
    test "cancels an active PnL subscription" do
      client = start_client()

      {:ok, ref} = Account.pnl(client, "DU123456")
      assert :ok = Account.unsubscribe_pnl(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = Account.unsubscribe_pnl(client, fake_ref)
    end
  end

  describe "unsubscribe_pnl_single/2" do
    test "cancels an active PnLSingle subscription" do
      client = start_client()

      {:ok, ref} = Account.pnl_single(client, "DU123456", 265_598)
      assert :ok = Account.unsubscribe_pnl_single(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = Account.unsubscribe_pnl_single(client, fake_ref)
    end
  end
end
