defmodule IbEx.Client.OptionsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.Options
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
  @tick_option_computation_wire_id 221
  @sec_def_opt_parameter_wire_id 275
  @sec_def_opt_parameter_end_wire_id 276
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  defp sample_contract do
    %Proto.Contract{symbol: "AAPL", sec_type: "OPT", currency: "USD", exchange: "SMART"}
  end

  describe "implied_volatility/5" do
    test "subscribes to implied volatility calculations and receives TickOptionComputation messages" do
      client = start_client()

      {:ok, ref} = Options.implied_volatility(client, sample_contract(), 10.50, 155.0)
      assert is_reference(ref)

      tick = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 13,
        tick_attrib: 0,
        implied_vol: 0.2534,
        delta: 0.65,
        opt_price: 10.50,
        pv_dividend: 0.12,
        gamma: 0.045,
        vega: 0.32,
        theta: -0.08,
        und_price: 155.0
      }

      Client.process_message(client, wire_message(@tick_option_computation_wire_id, tick))

      assert_receive {:ib_ex, ^ref, %Proto.TickOptionComputation{} = received}, 1_000
      assert received.req_id == 1
      assert received.tick_type == 13
      assert received.implied_vol == 0.2534
      assert received.delta == 0.65
      assert received.opt_price == 10.50
      assert received.pv_dividend == 0.12
      assert received.gamma == 0.045
      assert received.vega == 0.32
      assert received.theta == -0.08
      assert received.und_price == 155.0
    end

    test "receives multiple TickOptionComputation updates on the same subscription" do
      client = start_client()

      {:ok, ref} = Options.implied_volatility(client, sample_contract(), 10.50, 155.0)

      tick_1 = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 13,
        implied_vol: 0.2534,
        delta: 0.65,
        opt_price: 10.50,
        und_price: 155.0
      }

      tick_2 = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 13,
        implied_vol: 0.2580,
        delta: 0.66,
        opt_price: 10.75,
        und_price: 155.5
      }

      Client.process_message(client, wire_message(@tick_option_computation_wire_id, tick_1))
      Client.process_message(client, wire_message(@tick_option_computation_wire_id, tick_2))

      assert_receive {:ib_ex, ^ref, %Proto.TickOptionComputation{implied_vol: 0.2534, delta: 0.65}}, 1_000
      assert_receive {:ib_ex, ^ref, %Proto.TickOptionComputation{implied_vol: 0.2580, delta: 0.66}}, 1_000
    end

    test "receives error messages for the subscription" do
      client = start_client()

      {:ok, ref} = Options.implied_volatility(client, sample_contract(), 10.50, 155.0)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end
  end

  describe "cancel_implied_volatility/2" do
    test "cancels an active implied volatility subscription" do
      client = start_client()

      {:ok, ref} = Options.implied_volatility(client, sample_contract(), 10.50, 155.0)
      assert :ok = Options.cancel_implied_volatility(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = Options.cancel_implied_volatility(client, fake_ref)
    end
  end

  describe "option_price/5" do
    test "subscribes to option price calculations and receives TickOptionComputation messages" do
      client = start_client()

      {:ok, ref} = Options.option_price(client, sample_contract(), 0.25, 155.0)
      assert is_reference(ref)

      tick = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 13,
        tick_attrib: 0,
        implied_vol: 0.25,
        delta: 0.62,
        opt_price: 9.85,
        pv_dividend: 0.12,
        gamma: 0.042,
        vega: 0.30,
        theta: -0.07,
        und_price: 155.0
      }

      Client.process_message(client, wire_message(@tick_option_computation_wire_id, tick))

      assert_receive {:ib_ex, ^ref, %Proto.TickOptionComputation{} = received}, 1_000
      assert received.req_id == 1
      assert received.tick_type == 13
      assert received.implied_vol == 0.25
      assert received.delta == 0.62
      assert received.opt_price == 9.85
      assert received.pv_dividend == 0.12
      assert received.gamma == 0.042
      assert received.vega == 0.30
      assert received.theta == -0.07
      assert received.und_price == 155.0
    end

    test "receives multiple TickOptionComputation updates on the same subscription" do
      client = start_client()

      {:ok, ref} = Options.option_price(client, sample_contract(), 0.25, 155.0)

      tick_1 = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 13,
        implied_vol: 0.25,
        delta: 0.62,
        opt_price: 9.85,
        und_price: 155.0
      }

      tick_2 = %Proto.TickOptionComputation{
        req_id: 1,
        tick_type: 13,
        implied_vol: 0.25,
        delta: 0.63,
        opt_price: 10.10,
        und_price: 155.5
      }

      Client.process_message(client, wire_message(@tick_option_computation_wire_id, tick_1))
      Client.process_message(client, wire_message(@tick_option_computation_wire_id, tick_2))

      assert_receive {:ib_ex, ^ref, %Proto.TickOptionComputation{opt_price: 9.85, delta: 0.62}}, 1_000
      assert_receive {:ib_ex, ^ref, %Proto.TickOptionComputation{opt_price: 10.10, delta: 0.63}}, 1_000
    end

    test "receives error messages for the subscription" do
      client = start_client()

      {:ok, ref} = Options.option_price(client, sample_contract(), 0.25, 155.0)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "No security definition has been found for the request"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert_receive {:ib_ex, ^ref, {:error, %IbEx.Client.Types.Error{} = error}}, 1_000
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end
  end

  describe "cancel_option_price/2" do
    test "cancels an active option price subscription" do
      client = start_client()

      {:ok, ref} = Options.option_price(client, sample_contract(), 0.25, 155.0)
      assert :ok = Options.cancel_option_price(client, ref)
    end

    test "returns error for unknown subscription ref" do
      client = start_client()
      fake_ref = make_ref()

      assert {:error, :not_found} = Options.cancel_option_price(client, fake_ref)
    end
  end

  describe "sec_def_params/5" do
    test "accumulates SecDefOptParameter responses and returns {:ok, list} on SecDefOptParameterEnd" do
      client = start_client()

      task =
        Task.async(fn ->
          Options.sec_def_params(client, "AAPL", "STK", 265_598, timeout: 5_000)
        end)

      Process.sleep(50)

      param_1 = %Proto.SecDefOptParameter{
        req_id: 1,
        exchange: "SMART",
        underlying_con_id: 265_598,
        trading_class: "AAPL",
        multiplier: "100",
        expirations: ["20250117", "20250221"],
        strikes: [140.0, 145.0, 150.0, 155.0, 160.0]
      }

      param_2 = %Proto.SecDefOptParameter{
        req_id: 1,
        exchange: "CBOE",
        underlying_con_id: 265_598,
        trading_class: "AAPL",
        multiplier: "100",
        expirations: ["20250117"],
        strikes: [145.0, 150.0, 155.0]
      }

      Client.process_message(client, wire_message(@sec_def_opt_parameter_wire_id, param_1))
      Client.process_message(client, wire_message(@sec_def_opt_parameter_wire_id, param_2))

      end_marker = %Proto.SecDefOptParameterEnd{req_id: 1}
      Client.process_message(client, wire_message(@sec_def_opt_parameter_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 2

      [first, second] = results
      assert %Proto.SecDefOptParameter{} = first
      assert first.req_id == 1
      assert first.exchange == "SMART"
      assert first.underlying_con_id == 265_598
      assert first.trading_class == "AAPL"
      assert first.multiplier == "100"
      assert first.expirations == ["20250117", "20250221"]
      assert first.strikes == [140.0, 145.0, 150.0, 155.0, 160.0]

      assert %Proto.SecDefOptParameter{} = second
      assert second.exchange == "CBOE"
      assert second.expirations == ["20250117"]
      assert second.strikes == [145.0, 150.0, 155.0]
    end

    test "returns {:ok, []} when no option parameters exist" do
      client = start_client()

      task =
        Task.async(fn ->
          Options.sec_def_params(client, "AAPL", "STK", 265_598, timeout: 5_000)
        end)

      Process.sleep(50)

      end_marker = %Proto.SecDefOptParameterEnd{req_id: 1}
      Client.process_message(client, wire_message(@sec_def_opt_parameter_end_wire_id, end_marker))

      assert {:ok, []} = Task.await(task, 5_000)
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          Options.sec_def_params(client, "INVALID", "STK", 0, timeout: 5_000)
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
      assert error.id == 1
      assert error.code == 200
      assert error.message == "No security definition has been found for the request"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          Options.sec_def_params(client, "AAPL", "STK", 265_598, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end

    test "passes fut_fop_exchange option to the request" do
      client = start_client()

      task =
        Task.async(fn ->
          Options.sec_def_params(client, "ES", "FUT", 551_601_561, fut_fop_exchange: "CME", timeout: 5_000)
        end)

      Process.sleep(50)

      param = %Proto.SecDefOptParameter{
        req_id: 1,
        exchange: "CME",
        underlying_con_id: 551_601_561,
        trading_class: "ES",
        multiplier: "50",
        expirations: ["20250321"],
        strikes: [5000.0, 5100.0, 5200.0]
      }

      Client.process_message(client, wire_message(@sec_def_opt_parameter_wire_id, param))

      end_marker = %Proto.SecDefOptParameterEnd{req_id: 1}
      Client.process_message(client, wire_message(@sec_def_opt_parameter_end_wire_id, end_marker))

      assert {:ok, results} = Task.await(task, 5_000)
      assert length(results) == 1

      [result] = results
      assert result.exchange == "CME"
      assert result.trading_class == "ES"
      assert result.multiplier == "50"
      assert result.strikes == [5000.0, 5100.0, 5200.0]
    end
  end
end
