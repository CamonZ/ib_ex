defmodule IbEx.TraceServer do
    @moduledoc """
    Dev/test-only GenServer that captures parsed TWS messages for inspection.

    Maintains a bounded FIFO buffer (default max 1000 entries) of trace entries
    with timestamp, message struct, type module, req_id, and order_id.

    ## Usage

        IbEx.TraceServer.messages()
        IbEx.TraceServer.messages(type: IbEx.Client.Proto.Protobuf.TickPrice)
        IbEx.TraceServer.messages(req_id: 1)
        IbEx.TraceServer.messages(req_id: 1, type: IbEx.Client.Proto.Protobuf.TickPrice)
        IbEx.TraceServer.count()
        IbEx.TraceServer.clear()
    """

    use GenServer

    @default_max_size 1000

    defstruct buffer: :queue.new(), size: 0, max_size: @default_max_size

    # Public API

    def start_link(opts \\ []) do
      max_size = Keyword.get(opts, :max_size, @default_max_size)
      GenServer.start_link(__MODULE__, max_size, name: Keyword.get(opts, :name, __MODULE__))
    end

    def trace(msg, server \\ __MODULE__) do
      GenServer.cast(server, {:trace, msg})
    end

    def messages(filters \\ [], server \\ __MODULE__) do
      GenServer.call(server, {:messages, filters})
    end

    def count(server \\ __MODULE__) do
      GenServer.call(server, :count)
    end

    def clear(server \\ __MODULE__) do
      GenServer.call(server, :clear)
    end

    # Server callbacks

    @impl true
    def init(max_size) do
      {:ok, %__MODULE__{max_size: max_size}}
    end

    @impl true
    def handle_cast({:trace, msg}, state) do
      entry = build_entry(msg)
      {buffer, size} = enqueue(state.buffer, state.size, state.max_size, entry)
      {:noreply, %{state | buffer: buffer, size: size}}
    end

    @impl true
    def handle_call({:messages, filters}, _from, state) do
      entries = :queue.to_list(state.buffer)
      result = apply_filters(entries, filters)
      {:reply, result, state}
    end

    def handle_call(:count, _from, state) do
      {:reply, state.size, state}
    end

    def handle_call(:clear, _from, state) do
      {:reply, :ok, %{state | buffer: :queue.new(), size: 0}}
    end

    # Private functions

    defp build_entry(%module{} = msg) do
      %{
        timestamp: DateTime.utc_now(),
        message: msg,
        type: module,
        req_id: Map.get(msg, :req_id),
        order_id: Map.get(msg, :order_id)
      }
    end

    defp build_entry(msg) do
      %{
        timestamp: DateTime.utc_now(),
        message: msg,
        type: nil,
        req_id: nil,
        order_id: nil
      }
    end

    defp enqueue(buffer, size, max_size, entry) when size >= max_size do
      {_, buffer} = :queue.out(buffer)
      {:queue.in(entry, buffer), size}
    end

    defp enqueue(buffer, size, _max_size, entry) do
      {:queue.in(entry, buffer), size + 1}
    end

    defp apply_filters(entries, []), do: entries

    defp apply_filters(entries, filters) do
      Enum.filter(entries, fn entry ->
        Enum.all?(filters, fn
          {:type, type} -> entry.type == type
          {:req_id, id} -> entry.req_id == id
          {:order_id, id} -> entry.order_id == id
        end)
      end)
    end
end
