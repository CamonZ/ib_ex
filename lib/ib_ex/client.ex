defmodule IbEx.Client do
  @moduledoc """
  Client server for sending or receiving messages to/from the IBKR
  Trader Workstation

  During init this server spawns a process for the `Connection`
  which asynchronously opens the TCP connection with the TWS.
  Once the connection is established the connection process sends a message
  to this server notifying it, which in turn makes this server start the
  API client initialization process.

  This happens by sending an `InitConnection.Request` request
  which is then replied with a
  `InitConnection.Response` message with the TWS server version and the TWS time.

  After the `InitConnection.Response` is received then we send the `StartApi.Request` message
  which the TWS server replies with:
  * Account number
  * Next valid ID (presumably for order placement)
  * Info messages regarding which data farms are connected

  """

  use GenServer

  # @connection_statuses [:disconnected, :connecting, :connected]

  defstruct connection: nil,
            client_id: 0,
            optional_capabilities: "",
            status: :disconnected,
            server_version: nil,
            server_time: nil,
            managed_accounts: nil,
            next_valid_id: nil

  alias IbEx.Client.Connection
  alias IbEx.Client.Constants
  alias IbEx.Client.Messages
  alias IbEx.Client.Messages.Responses

  require Logger

  def connection_opened(pid) do
    GenServer.cast(pid, :connection_opened)
  end

  def process_message(pid, str) do
    GenServer.cast(pid, {:process_message, str})
  end

  def send_request(pid, request) do
    GenServer.cast(pid, {:send_request, request})
  end

  def request_historical_ticks(pid, opts) do
    case Messages.HistoricalTicks.Request.new(opts) do
      {:ok, msg} ->
        send_request(pid, msg)

      error ->
        error
    end
  end

  def server_time(pid) do
    case Messages.CurrentTime.Request.new() do
      {:ok, msg} ->
        send_request(pid, msg)

      other ->
        other
    end
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    connection_opts =
      opts
      |> Keyword.take([:host, :port])
      |> Keyword.put(:client, self())

    case Connection.start_link(connection_opts) do
      {:ok, pid} ->
        {:ok, %__MODULE__{connection: pid}}

      err ->
        {:stop, {:connection_error, err}}
    end
  end

  # 1 We init the connection by sending the InitConnection Request
  # 2 Then the reply is the connection ack message
  # 3 we validate the server version and continue to the request start api request
  def handle_continue(:init_connection, state) do
    {:ok, msg} = Messages.InitConnection.Request.new()

    Connection.send_message(state.connection, msg)
    Connection.set_packet_mode_on(state.connection)

    {:noreply, %{state | status: :connecting}}
  rescue
    err ->
      {:stop, {:error_initializing_connection, err}}
  end

  @min_version_tag :pending_price_revision

  def handle_continue(:validate_server_version, state) do
    case validate_server_version_for(@min_version_tag, state) do
      {:ok, :required_version_met} ->
        {:noreply, state, {:continue, :request_start_api}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_continue(:request_start_api, state) do
    msg_opts = [
      client_id: state.client_id,
      optional_capabilities: optional_capabilities(state)
    ]

    {:ok, start_api_msg} = Messages.StartApi.Request.new(msg_opts)
    Connection.send_message(state.connection, start_api_msg)

    {:noreply, state}
  rescue
    _ ->
      {:stop, state}
  end

  # Triggered by the Connection process once the connection is open
  def handle_cast(:connection_opened, state) do
    {:noreply, state, {:continue, :init_connection}}
  end

  def handle_cast({:process_message, str}, state) do
    case Responses.parse(str, state.status) do
      {:ok, %Messages.InitConnection.Response{} = msg} ->
        Logger.warning("#{inspect(msg)}")

        update = %{
          server_version: msg.server_version,
          server_time: msg.server_time,
          status: :connected
        }

        {:noreply, Map.merge(state, update), {:continue, :validate_server_version}}

      {:ok, %Messages.Misc.ManagedAccounts{} = msg} ->
        {:noreply, Map.put(state, :managed_accounts, msg.accounts)}

      {:ok, %Messages.Ids.NextValidId{} = msg} ->
        {:noreply, Map.put(state, :next_valid_id, msg.next_valid_id)}

      {:ok, _} ->
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:send_request, request}, state) do
    Connection.send_message(state.connection, request)

    {:noreply, state}
  end

  defp optional_capabilities(state) do
    case validate_server_version_for(:optional_capabilities, state) do
      {:ok, :required_version_met} ->
        state.optional_capabilities

      _ ->
        nil
    end
  end

  defp validate_server_version_for(message_type, state) do
    with {:ok, required_version} <- Constants.ServerVersions.version_for(message_type),
         true <- state.server_version >= required_version do
      {:ok, :required_version_met}
    else
      _ ->
        {:error, {:required_version_unmet, message_type, state.server_version}}
    end
  end
end
