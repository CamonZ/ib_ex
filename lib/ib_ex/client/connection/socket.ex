defmodule IbEx.Client.Connection.Socket do
  @spec connect(host: binary(), port: non_neg_integer()) ::
          {:ok, :gen_tcp.socket()} | {:error, any()}
  def connect(host: host, port: port) do
    :gen_tcp.connect(host, port, [{:mode, :binary}, {:active, true}])
  end

  @spec disconnect(:gen_tcp.socket()) :: :ok
  def disconnect(socket) do
    :gen_tcp.close(socket)
  end

  @spec send_message(:gen_tcp.socket(), binary()) ::
          :ok | {:error, :closed} | {:error, {:timeout, binary()}} | {:error, :inet.posix()}
  def send_message(socket, msg) do
    :gen_tcp.send(socket, msg)
  end

  @spec set_packet_mode_on(:gen_tcp.socket()) :: :ok | :inet.posix()
  def set_packet_mode_on(socket) do
    :inet.setopts(socket, [{:packet, 4}])
  end
end
