defmodule IbEx.Client.Connection do
  use GenServer

  @default_host {127, 0, 0, 1}
  @default_port 7496

  defstruct host: nil, port: nil, socket: nil, client: nil

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

    case Keyword.fetch(opts, :client) do
      {:ok, client} ->
        GenServer.start_link(__MODULE__, host: host, port: port, client: client)

      :error ->
        {:error, :invalid_args}
    end
  end

  def start_link(_) do
    {:error, :invalid_args}
  end

  @impl true
  def init(host: host, port: port, client: client) do
    case Socket.connect(host: host, port: port) do
      {:ok, socket} ->
        Logger.info("Socket connection established")

        state = %__MODULE__{host: host, port: port, socket: socket, client: client}
        {:ok, state, {:continue, :signal_connection_open}}

      {:error, reason} ->
        Logger.error("Error stablishing connection: #{inspect(reason)}")
        {:stop, :connection_error}
    end
  rescue
    err ->
      Logger.error("Error stablishing connection: #{inspect(err)}")
      {:stop, :connection_error}
  end

  # Notify parent client that the connection is open
  @impl true
  def handle_continue(:signal_connection_open, state) do
    Client.connection_opened(state.client)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:set_packet_mode_on, state) do
    Socket.set_packet_mode_on(state.socket)
    {:noreply, state}
  end

  @impl true
  def handle_call({:send_message, msg}, _from, state) do
    Logger.info("#{inspect(msg)}")
    Socket.send_message(state.socket, to_string(msg))

    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:tcp, _, data}, state) do
    Logger.info("<- #{IO.inspect(data, limit: :infinity)}")
    Client.process_message(state.client, data)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _}, state) do
    Logger.warning("TCP CLOSED")
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
