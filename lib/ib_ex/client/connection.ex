defmodule IbEx.Client.Connection do
  use GenServer

  @default_host {127, 0, 0, 1}
  @default_port 7496

  @reconnect_interval_ms 2_000

  defstruct host: nil,
            port: nil,
            socket: nil,
            client: nil,
            reconnect_timer_ref: nil,
            auto_reconnect: true

  alias IbEx.Client
  alias __MODULE__.Socket

  require Logger

  def send_message(pid, msg) do
    GenServer.call(pid, {:send_message, msg})
  end

  def set_packet_mode_on(pid) do
    GenServer.cast(pid, :set_packet_mode_on)
  end

  def start_link(opts) when is_list(opts) do
    host = Keyword.get(opts, :host, @default_host)
    port = Keyword.get(opts, :port, @default_port)
    auto_reconnect = Keyword.get(opts, :auto_reconnect, true)

    case Keyword.fetch(opts, :client) do
      {:ok, client} ->
        GenServer.start_link(__MODULE__, host: host, port: port, client: client, auto_reconnect: auto_reconnect)

      :error ->
        {:error, :invalid_args}
    end
  end

  def start_link(_) do
    {:error, :invalid_args}
  end

  @impl true
  def init(opts) do
    host = Keyword.fetch!(opts, :host)
    port = Keyword.fetch!(opts, :port)
    client = Keyword.fetch!(opts, :client)
    auto_reconnect = Keyword.get(opts, :auto_reconnect, true)

    case Socket.connect(host: host, port: port) do
      {:ok, socket} ->
        Logger.info("Socket connection established")

        state = %__MODULE__{host: host, port: port, socket: socket, client: client, auto_reconnect: auto_reconnect}
        {:ok, state, {:continue, :signal_connection_open}}

      {:error, reason} ->
        Logger.error("Error establishing connection: #{inspect(reason)}")
        {:stop, :connection_error}
    end
  rescue
    err ->
      Logger.error("Error establishing connection: #{inspect(err)}")
      {:stop, :connection_error}
  end

  # Notify parent client that the connection is open
  @impl true
  def handle_continue(:signal_connection_open, state) do
    Client.connection_opened(state.client)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:set_packet_mode_on, %{socket: nil} = state) do
    {:noreply, state}
  end

  def handle_cast(:set_packet_mode_on, state) do
    Socket.set_packet_mode_on(state.socket)
    {:noreply, state}
  end

  @impl true
  def handle_call({:send_message, _data}, _from, %{socket: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  @impl true
  def handle_call({:send_message, data}, _from, state) do
    case Socket.send_message(state.socket, data) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("Error sending message: #{inspect(reason)}")

        if state.auto_reconnect do
          {:reply, {:error, reason}, schedule_reconnect(%{state | socket: nil})}
        else
          {:stop, {:send_error, reason}, {:error, reason}, %{state | socket: nil}}
        end
    end
  end

  @impl true
  def handle_info({:tcp, _, data}, state) do
    Client.process_message(state.client, data)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _}, state) do
    Client.connection_closed(state.client)

    if state.auto_reconnect do
      Logger.warning("TCP connection closed, scheduling reconnect in #{@reconnect_interval_ms}ms")
      {:noreply, schedule_reconnect(%{state | socket: nil})}
    else
      Logger.warning("TCP connection closed, stopping (auto_reconnect: false)")
      {:stop, :tcp_closed, %{state | socket: nil}}
    end
  end

  @impl true
  def handle_info({:tcp_error, _, reason}, state) do
    Client.connection_closed(state.client)

    if state.auto_reconnect do
      Logger.warning("TCP error: #{inspect(reason)}, scheduling reconnect in #{@reconnect_interval_ms}ms")
      {:noreply, schedule_reconnect(%{state | socket: nil})}
    else
      Logger.warning("TCP error: #{inspect(reason)}, stopping (auto_reconnect: false)")
      {:stop, {:tcp_error, reason}, %{state | socket: nil}}
    end
  end

  @impl true
  def handle_info(:reconnect, state) do
    state = %{state | reconnect_timer_ref: nil}

    case Socket.connect(host: state.host, port: state.port) do
      {:ok, socket} ->
        Logger.info("Socket reconnection established")
        {:noreply, %{state | socket: socket}, {:continue, :signal_connection_open}}

      {:error, reason} ->
        Logger.warning("Reconnect failed (#{inspect(reason)}), retrying in #{@reconnect_interval_ms}ms")
        {:noreply, schedule_reconnect(state)}
    end
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp schedule_reconnect(state) do
    timer_ref = Process.send_after(self(), :reconnect, @reconnect_interval_ms)
    %{state | reconnect_timer_ref: timer_ref}
  end
end
