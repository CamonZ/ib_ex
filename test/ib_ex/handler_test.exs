defmodule IbEx.HandlerTest do
  use ExUnit.Case, async: true

  defmodule DefaultHandler do
    use IbEx.Handler
  end

  defmodule CustomHandler do
    use IbEx.Handler

    @impl IbEx.Handler
    def handle_connected(context) do
      send(context.test_pid, {:connected, context})
      :ok
    end

    @impl IbEx.Handler
    def handle_error(error, context) do
      send(context.test_pid, {:error_received, error, context})
      :ok
    end
  end

  defmodule PartialHandler do
    use IbEx.Handler

    @impl IbEx.Handler
    def handle_disconnected(context) do
      send(context.test_pid, {:disconnected, context})
      :ok
    end
  end

  describe "behaviour definition" do
    test "defines handle_connected/1 as a callback" do
      callbacks = IbEx.Handler.behaviour_info(:callbacks)

      assert {:handle_connected, 1} in callbacks
    end

    test "defines handle_disconnected/1 as a callback" do
      callbacks = IbEx.Handler.behaviour_info(:callbacks)

      assert {:handle_disconnected, 1} in callbacks
    end

    test "defines handle_error/2 as a callback" do
      callbacks = IbEx.Handler.behaviour_info(:callbacks)

      assert {:handle_error, 2} in callbacks
    end

    test "all callbacks are optional" do
      optional = IbEx.Handler.behaviour_info(:optional_callbacks)

      assert {:handle_connected, 1} in optional
      assert {:handle_disconnected, 1} in optional
      assert {:handle_error, 2} in optional
    end

    test "defines exactly three callbacks" do
      callbacks = IbEx.Handler.behaviour_info(:callbacks)

      assert length(callbacks) == 3
    end
  end

  describe "default implementations via use IbEx.Handler" do
    test "handle_connected/1 returns :ok" do
      assert DefaultHandler.handle_connected(%{}) == :ok
    end

    test "handle_disconnected/1 returns :ok" do
      assert DefaultHandler.handle_disconnected(%{}) == :ok
    end

    test "handle_error/2 returns :ok" do
      assert DefaultHandler.handle_error(:some_error, %{}) == :ok
    end
  end

  describe "overriding callbacks" do
    test "handle_connected/1 can be overridden and receives context" do
      context = %{test_pid: self(), server_version: 213}

      assert CustomHandler.handle_connected(context) == :ok
      assert_receive {:connected, ^context}
    end

    test "handle_error/2 can be overridden and receives error and context" do
      error = {:connection_lost, :timeout}
      context = %{test_pid: self(), manager: :orders}

      assert CustomHandler.handle_error(error, context) == :ok
      assert_receive {:error_received, {:connection_lost, :timeout}, ^context}
    end

    test "non-overridden callbacks retain default behaviour" do
      assert CustomHandler.handle_disconnected(%{}) == :ok
    end
  end

  describe "partial override" do
    test "only overridden callback fires custom logic" do
      context = %{test_pid: self(), reason: :tcp_closed}

      assert PartialHandler.handle_disconnected(context) == :ok
      assert_receive {:disconnected, ^context}
    end

    test "handle_connected/1 retains default no-op" do
      assert PartialHandler.handle_connected(%{}) == :ok
      refute_receive {:connected, _}
    end

    test "handle_error/2 retains default no-op" do
      assert PartialHandler.handle_error(:boom, %{}) == :ok
      refute_receive {:error_received, _, _}
    end
  end
end
