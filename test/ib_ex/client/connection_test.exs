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

  describe "auto_reconnect: false" do
    @tag capture_log: true
    test "tcp_closed stops the process instead of scheduling reconnect" do
      state = build_state(%{auto_reconnect: false})

      assert {:stop, :tcp_closed, new_state} = Connection.handle_info({:tcp_closed, :fake_socket}, state)

      assert new_state.socket == nil
      assert new_state.reconnect_timer_ref == nil

      # Still notifies the client
      assert_receive {:"$gen_cast", :connection_closed}
    end

    @tag capture_log: true
    test "tcp_error stops the process with the error reason instead of scheduling reconnect" do
      state = build_state(%{auto_reconnect: false})

      assert {:stop, {:tcp_error, :econnreset}, new_state} =
               Connection.handle_info({:tcp_error, :fake_socket, :econnreset}, state)

      assert new_state.socket == nil
      assert new_state.reconnect_timer_ref == nil

      # Still notifies the client
      assert_receive {:"$gen_cast", :connection_closed}
    end

    @tag capture_log: true
    test "send_message error stops the process instead of scheduling reconnect" do
      # We need a real (but broken) socket to trigger a send error.
      # Create a socket and immediately close it so send fails.
      {:ok, listen_socket} = :gen_tcp.listen(0, reuseaddr: true)
      {:ok, port} = :inet.port(listen_socket)
      {:ok, client_socket} = :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false])
      :gen_tcp.close(client_socket)
      :gen_tcp.close(listen_socket)

      state = build_state(%{socket: client_socket, auto_reconnect: false})

      assert {:stop, {:send_error, reason}, {:error, reason}, new_state} =
               Connection.handle_call({:send_message, "data"}, {self(), make_ref()}, state)

      assert is_atom(reason)

      assert new_state.socket == nil
    end
  end

  describe "auto_reconnect: true (default)" do
    test "build_state defaults to auto_reconnect: true" do
      state = build_state()
      assert state.auto_reconnect == true
    end

    @tag capture_log: true
    test "tcp_closed schedules reconnect when auto_reconnect is true" do
      state = build_state(%{auto_reconnect: true})

      assert {:noreply, new_state} = Connection.handle_info({:tcp_closed, :fake_socket}, state)

      assert new_state.socket == nil
      assert is_reference(new_state.reconnect_timer_ref)

      assert_receive {:"$gen_cast", :connection_closed}

      Process.cancel_timer(new_state.reconnect_timer_ref)
    end

    @tag capture_log: true
    test "tcp_error schedules reconnect when auto_reconnect is true" do
      state = build_state(%{auto_reconnect: true})

      assert {:noreply, new_state} = Connection.handle_info({:tcp_error, :fake_socket, :econnreset}, state)

      assert new_state.socket == nil
      assert is_reference(new_state.reconnect_timer_ref)

      assert_receive {:"$gen_cast", :connection_closed}

      Process.cancel_timer(new_state.reconnect_timer_ref)
    end
  end
end
