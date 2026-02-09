defmodule IbEx.Client.SystemTest do
  use ExUnit.Case, async: true

  alias IbEx.Client
  alias IbEx.Client.System
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
  @current_time_wire_id 249
  @current_time_in_millis_wire_id 309
  @user_info_wire_id 307
  @config_response_wire_id 310
  @error_message_wire_id 204

  defp wire_message(wire_id, proto_struct) do
    payload = Protobuf.encode(proto_struct)
    <<wire_id::big-integer-size(32), payload::binary>>
  end

  defp start_client do
    {:ok, pid} = Client.start_link(connection_handler: MockConnection)
    pid
  end

  describe "current_time/2" do
    test "sends CurrentTimeRequest and returns {:ok, %CurrentTime{}} on response" do
      client = start_client()

      task =
        Task.async(fn ->
          System.current_time(client, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.CurrentTime{current_time: 1_700_000_000}
      Client.process_message(client, wire_message(@current_time_wire_id, response))

      assert {:ok, %Proto.CurrentTime{} = result} = Task.await(task, 5_000)
      assert result.current_time == 1_700_000_000
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          System.current_time(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "current_time_millis/2" do
    test "sends CurrentTimeInMillisRequest and returns {:ok, %CurrentTimeInMillis{}} on response" do
      client = start_client()

      task =
        Task.async(fn ->
          System.current_time_millis(client, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.CurrentTimeInMillis{current_time_in_millis: 1_700_000_000_123}
      Client.process_message(client, wire_message(@current_time_in_millis_wire_id, response))

      assert {:ok, %Proto.CurrentTimeInMillis{} = result} = Task.await(task, 5_000)
      assert result.current_time_in_millis == 1_700_000_000_123
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          System.current_time_millis(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "set_log_level/2" do
    test "sends SetServerLogLevelRequest and returns :ok" do
      client = start_client()

      assert :ok = System.set_log_level(client, 5)
    end

    test "accepts all valid log levels" do
      client = start_client()

      for level <- [1, 2, 3, 4, 5] do
        assert :ok = System.set_log_level(client, level)
      end
    end
  end

  describe "config/2" do
    test "sends ConfigRequest and returns {:ok, %ConfigResponse{}} on response" do
      client = start_client()

      task =
        Task.async(fn ->
          System.config(client, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.ConfigResponse{
        req_id: 1,
        messages: [],
        api: %Proto.ApiConfig{},
        orders: %Proto.OrdersConfig{}
      }

      Client.process_message(client, wire_message(@config_response_wire_id, response))

      assert {:ok, %Proto.ConfigResponse{} = result} = Task.await(task, 5_000)
      assert result.req_id == 1
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          System.config(client, timeout: 5_000)
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
          System.config(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end

  describe "user_info/2" do
    test "sends UserInfoRequest and returns {:ok, %UserInfo{}} on response" do
      client = start_client()

      task =
        Task.async(fn ->
          System.user_info(client, timeout: 5_000)
        end)

      Process.sleep(50)

      response = %Proto.UserInfo{
        req_id: 1,
        white_branding_id: "branding-123"
      }

      Client.process_message(client, wire_message(@user_info_wire_id, response))

      assert {:ok, %Proto.UserInfo{} = result} = Task.await(task, 5_000)
      assert result.req_id == 1
      assert result.white_branding_id == "branding-123"
    end

    test "returns {:error, error} when TWS sends ErrorMessage for the req_id" do
      client = start_client()

      task =
        Task.async(fn ->
          System.user_info(client, timeout: 5_000)
        end)

      Process.sleep(50)

      error_proto = %Proto.ErrorMessage{
        id: 1,
        error_code: 200,
        error_msg: "User info not available"
      }

      Client.process_message(client, wire_message(@error_message_wire_id, error_proto))

      assert {:error, error} = Task.await(task, 5_000)
      assert %IbEx.Client.Types.Error{} = error
      assert error.id == 1
      assert error.code == 200
      assert error.message == "User info not available"
    end

    test "returns {:error, :timeout} when no response arrives within the timeout window" do
      client = start_client()

      result =
        try do
          System.user_info(client, timeout: 100)
        catch
          :exit, {:timeout, _} -> {:error, :timeout}
        end

      assert {:error, :timeout} = result
    end
  end
end
