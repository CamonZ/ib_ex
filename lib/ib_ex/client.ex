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
            optional_capabilities: "",
            client_id: 0,
            status: :disconnected,
            server_version: nil,
            connection_timestamp: nil,
            managed_accounts: nil,
            next_valid_id: nil,
            subscriptions_table_ref: nil,
            trace_messages: false

  alias IbEx.Client.Connection
  alias IbEx.Client.Constants
  alias IbEx.Client.Conversations
  alias IbEx.Client.Messages
  alias IbEx.Client.Messages.Responses
  alias IbEx.Client.Subscriptions
  alias IbEx.Client.Types

  require Logger

  @default_timeout 5_000

  def connection_opened(pid) do
    GenServer.cast(pid, :connection_opened)
  end

  def process_message(pid, str) do
    GenServer.cast(pid, {:process_message, str})
  end

  def request(pid, proto_msg, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    GenServer.call(pid, {:request, proto_msg, opts}, timeout)
  end

  def subscribe(pid, proto_msg, opts \\ []) do
    GenServer.call(pid, {:subscribe, self(), proto_msg, opts})
  end

  def unsubscribe(pid, subscription_ref) do
    GenServer.call(pid, {:unsubscribe, subscription_ref})
  end

  def command(pid, proto_msg) do
    GenServer.call(pid, {:command, proto_msg})
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    connection_opts =
      opts
      |> Keyword.take([:host, :port])
      |> Keyword.put(:client, self())

    connection_handler = Keyword.get(opts, :connection_handler, Connection)

    case connection_handler.start_link(connection_opts) do
      {:ok, pid} ->
        table_ref = Subscriptions.initialize()
        trace_messages = Keyword.get(opts, :trace_messages, false)

        {:ok, %__MODULE__{connection: pid, subscriptions_table_ref: table_ref, trace_messages: trace_messages}}

      err ->
        {:stop, {:connection_error, err}}
    end
  end

  # 1 We init the connection by sending the InitConnection Request
  # 2 Then the reply is the connection ack message
  # 3 we validate the server version and continue to the request start api request
  def handle_continue(:init_connection, state) do
    {:ok, msg} = Messages.InitConnection.Request.new()

    Connection.send_message(state.connection, to_string(msg))
    Connection.set_packet_mode_on(state.connection)

    {:noreply, %{state | status: :connecting}}
  rescue
    err ->
      {:stop, {:error_initializing_connection, err}}
  end

  @min_version_tag :protobuf_rest_messages_3

  def handle_continue(:validate_server_version, state) do
    case validate_server_version_for(@min_version_tag, state) do
      {:ok, :required_version_met} ->
        {:noreply, state, {:continue, :request_start_api}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_continue(:request_start_api, state) do
    start_api_msg = %IbEx.Client.Proto.Protobuf.StartApiRequest{
      client_id: state.client_id,
      optional_capabilities: optional_capabilities(state)
    }

    {:ok, encoded} = Messages.Requests.encode_request(start_api_msg)
    Connection.send_message(state.connection, encoded)

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
    case Responses.parse(str, state.status, state.trace_messages) do
      {:ok, %Messages.InitConnection.Response{} = msg} ->
        update = %{
          server_version: msg.server_version,
          connection_timestamp: msg.connection_timestamp,
          status: :connected
        }

        {:noreply, Map.merge(state, update), {:continue, :validate_server_version}}

      {:ok, %IbEx.Client.Proto.Protobuf.ManagedAccounts{} = msg} ->
        {:noreply, Map.put(state, :managed_accounts, msg.accounts_list)}

      {:ok, %IbEx.Client.Proto.Protobuf.NextValidId{} = msg} ->
        {:noreply, Map.put(state, :next_valid_id, msg.order_id)}

      {:ok, msg} ->
        dispatch_message(msg, state.subscriptions_table_ref)
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_call({:request, %message_type{} = proto_msg, opts}, from, state) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    case join_existing_conversation(state, message_type, proto_msg, from, timeout) do
      {:ok, _key} ->
        send_to_tws(state, proto_msg)
        {:noreply, state}

      :not_applicable ->
        case Conversations.register_request(state.subscriptions_table_ref, message_type, from, timeout, self()) do
          {:ok, _key, req_id} when is_integer(req_id) ->
            send_to_tws(state, %{proto_msg | req_id: req_id})
            {:noreply, state}

          {:ok, _key, nil} ->
            send_to_tws(state, proto_msg)
            {:noreply, state}

          :error ->
            {:reply, {:error, :unknown_conversation}, state}
        end
    end
  end

  def handle_call({:subscribe, subscriber, %message_type{} = proto_msg, _opts}, _from, state) do
    case Conversations.register_stream(state.subscriptions_table_ref, message_type, subscriber) do
      {:ok, req_id, subscription_ref} ->
        proto_msg = set_correlation_id(message_type, proto_msg, req_id)
        send_to_tws(state, proto_msg)
        {:reply, {:ok, subscription_ref}, state}

      :error ->
        {:reply, {:error, :unknown_conversation}, state}
    end
  end

  def handle_call({:unsubscribe, subscription_ref}, _from, state) do
    table_ref = state.subscriptions_table_ref

    case Subscriptions.lookup_by_subscription_ref(table_ref, subscription_ref) do
      {:ok, key, entry} ->
        cancel_stream(state, table_ref, key, entry)
        {:reply, :ok, state}

      {:error, :missing_subscription} ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:command, proto_msg}, _from, state) do
    send_to_tws(state, proto_msg)
    {:reply, :ok, state}
  end

  def handle_info({:request_timeout, key}, state) do
    table_ref = state.subscriptions_table_ref

    case Subscriptions.lookup(table_ref, key) do
      {:ok, %{type: :request, from: from} = entry} ->
        GenServer.reply(from, {:error, :timeout})
        Subscriptions.remove_entry(table_ref, key, entry)

      _ ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, monitor_ref, :process, _pid, _reason}, state) do
    table_ref = state.subscriptions_table_ref

    case Subscriptions.lookup_by_monitor_ref(table_ref, monitor_ref) do
      {:ok, key, entry} ->
        cancel_stream(state, table_ref, key, entry)

      {:error, :missing_subscription} ->
        :ok
    end

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

  defp send_to_tws(state, msg) do
    case Messages.Requests.encode_request(msg) do
      {:ok, encoded} -> Connection.send_message(state.connection, encoded)
      _ -> Logger.error("Error encoding request: #{inspect(msg)}")
    end
  end

  defp cancel_stream(state, table_ref, key, %{monitor_ref: monitor_ref, request_module: request_module} = entry) do
    Process.demonitor(monitor_ref, [:flush])

    case Conversations.cancel_request_for(request_module) do
      {:ok, cancel_module} ->
        case key do
          {:request_id, req_id} ->
            send_to_tws(state, struct!(cancel_module, req_id: req_id))

          {:order_id, order_id} ->
            send_to_tws(state, struct!(cancel_module, order_id: order_id))

          {:global, _request_module} ->
            send_to_tws(state, struct!(cancel_module))
        end

      :error ->
        :ok
    end

    Subscriptions.remove_entry(table_ref, key, entry)
  end

  # Checks if the request should join an existing conversation (e.g. CancelOrderRequest
  # joining a PlaceOrder lifecycle on the same order_id key).
  defp join_existing_conversation(state, message_type, proto_msg, from, timeout) do
    case Conversations.conversation_for(message_type) do
      {:ok, %{correlation: :order_id, type: type}} when type != :stream ->
        order_id = Map.get(proto_msg, :order_id)

        if order_id do
          key = {:order_id, order_id}

          Conversations.register_request_on_existing_key(
            state.subscriptions_table_ref,
            message_type,
            key,
            from,
            timeout,
            self()
          )
        else
          :not_applicable
        end

      _ ->
        :not_applicable
    end
  end

  defp set_correlation_id(message_type, proto_msg, id) do
    case Conversations.conversation_for(message_type) do
      {:ok, %{correlation: :global}} -> proto_msg
      {:ok, %{correlation: :order_id}} -> %{proto_msg | order_id: id}
      _ -> %{proto_msg | req_id: id}
    end
  end

  defp dispatch_message(%Types.Error{id: id} = error, table_ref) when id > 0 do
    key = {:request_id, id}

    case Subscriptions.lookup_all(table_ref, key) do
      {:ok, entries} ->
        Enum.each(entries, fn
          %{type: :request} = entry ->
            complete_conversation(table_ref, key, entry, {:error, error})

          %{type: :stream, subscriber: subscriber, subscription_ref: ref} ->
            send(subscriber, {:ib_ex, ref, {:error, error}})
        end)

      _ ->
        :ok
    end
  end

  defp dispatch_message(%module{} = msg, table_ref) do
    case Map.get(msg, :req_id) do
      nil ->
        case Map.get(msg, :order_id) do
          nil -> dispatch_by_module(module, msg, table_ref)
          order_id -> dispatch_by_order_id({:order_id, order_id}, msg, module, table_ref)
        end

      req_id ->
        dispatch_by_req_id({:request_id, req_id}, msg, module, table_ref)
    end
  end

  defp dispatch_message(_msg, _table_ref), do: :ok

  defp dispatch_by_req_id(key, msg, module, table_ref) do
    case Subscriptions.lookup(table_ref, key) do
      {:ok, %{type: :request} = entry} ->
        handle_conversation_response(table_ref, key, msg, module, entry)

      {:ok, %{type: :stream, subscriber: subscriber, subscription_ref: ref}} ->
        send(subscriber, {:ib_ex, ref, msg})

      _ ->
        :ok
    end
  end

  defp dispatch_by_order_id(key, msg, module, table_ref) do
    case Subscriptions.lookup_all(table_ref, key) do
      {:ok, entries} ->
        Enum.each(entries, fn
          %{type: :stream, subscriber: subscriber, subscription_ref: ref} ->
            send(subscriber, {:ib_ex, ref, msg})

          %{type: :request} = entry ->
            handle_conversation_response(table_ref, key, msg, module, entry)
        end)

      _ ->
        dispatch_by_module(module, msg, table_ref)
    end
  end

  defp handle_conversation_response(table_ref, key, msg, module, entry) do
    {:ok, shape} = Conversations.conversation_for(entry.request_module)

    case shape.type do
      :request_response ->
        complete_conversation(table_ref, key, entry, {:ok, msg})

      :bounded_stream ->
        if Conversations.end_marker?(module) do
          {:ok, buffer} = Subscriptions.get_responses(table_ref, key)
          complete_conversation(table_ref, key, entry, {:ok, buffer})
        else
          Subscriptions.append_response(table_ref, key, msg)
        end
    end
  end

  defp complete_conversation(table_ref, key, %{from: from, timer_ref: timer_ref} = entry, reply) do
    Process.cancel_timer(timer_ref)
    GenServer.reply(from, reply)
    Subscriptions.remove_entry(table_ref, key, entry)
  end

  defp dispatch_by_module(module, msg, table_ref) do
    case find_global_conversation(module, table_ref) do
      {:ok, _key, %{type: :stream, subscriber: subscriber, subscription_ref: ref}} ->
        send(subscriber, {:ib_ex, ref, msg})

      {:ok, key, %{type: :request} = entry} ->
        handle_conversation_response(table_ref, key, msg, module, entry)

      :not_found ->
        case Subscriptions.lookup(table_ref, module) do
          {:ok, pid} when is_pid(pid) ->
            GenServer.cast(pid, {:message_received, msg})

          _ ->
            :ok
        end
    end
  end

  defp find_global_conversation(response_module, table_ref) do
    request_modules = Conversations.requests_for_response(response_module)

    Enum.find_value(request_modules, :not_found, fn request_module ->
      key = {:global, request_module}

      case Subscriptions.lookup(table_ref, key) do
        {:ok, entry} -> {:ok, key, entry}
        _ -> nil
      end
    end)
  end
end
