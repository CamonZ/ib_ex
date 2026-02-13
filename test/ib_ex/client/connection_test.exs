defmodule IbEx.Client.ConnectionTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Connection

  defp build_state(overrides \\ %{}) do
    Map.merge(
      %Connection{
        host: {127, 0, 0, 1},
        port: 7496,
        socket: :fake_socket,
        client: self(),
        reconnect_timer_ref: nil
      },
      overrides
    )
  end

  describe "handle_info({:tcp_closed, _})" do
    @tag capture_log: true
    test "sets socket to nil, notifies the client, and schedules a reconnect" do
      state = build_state()

      assert {:noreply, new_state} = Connection.handle_info({:tcp_closed, :fake_socket}, state)

      assert new_state.socket == nil
      assert is_reference(new_state.reconnect_timer_ref)

      # The Connection notifies the Client via connection_closed cast
      assert_receive {:"$gen_cast", :connection_closed}

      Process.cancel_timer(new_state.reconnect_timer_ref)
    end
  end

  describe "handle_info({:tcp_error, _, reason})" do
    @tag capture_log: true
    test "sets socket to nil, notifies the client, and schedules a reconnect" do
      state = build_state()

      assert {:noreply, new_state} = Connection.handle_info({:tcp_error, :fake_socket, :econnreset}, state)

      assert new_state.socket == nil
      assert is_reference(new_state.reconnect_timer_ref)

      assert_receive {:"$gen_cast", :connection_closed}

      Process.cancel_timer(new_state.reconnect_timer_ref)
    end
  end

  describe "handle_call({:send_message, _}) when socket is nil" do
    test "returns {:error, :not_connected}" do
      state = build_state(%{socket: nil})

      assert {:reply, {:error, :not_connected}, ^state} =
               Connection.handle_call({:send_message, "data"}, {self(), make_ref()}, state)
    end
  end

  describe "handle_info(:reconnect) when connection fails" do
    @tag capture_log: true
    test "schedules another reconnect attempt" do
      state = build_state(%{socket: nil, port: 1})

      assert {:noreply, new_state} = Connection.handle_info(:reconnect, state)

      assert new_state.socket == nil
      assert is_reference(new_state.reconnect_timer_ref)

      Process.cancel_timer(new_state.reconnect_timer_ref)
    end
  end

  describe "handle_info(:reconnect) when connection succeeds" do
    @tag capture_log: true
    test "restores socket and signals connection open" do
      {:ok, listen_socket} = :gen_tcp.listen(0, [{:reuseaddr, true}])
      {:ok, port} = :inet.port(listen_socket)

      state = build_state(%{socket: nil, port: port})

      assert {:noreply, new_state, {:continue, :signal_connection_open}} =
               Connection.handle_info(:reconnect, state)

      assert new_state.socket != nil
      assert new_state.reconnect_timer_ref == nil

      :gen_tcp.close(new_state.socket)
      :gen_tcp.close(listen_socket)
    end
  end
end
