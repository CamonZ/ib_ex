defmodule IbEx.Client.Subscriptions do
  @moduledoc """
  Handles initialization of the ETS table used by the client
  to map request ids or structs of a given message responses to the
  process that requested sending the message.

  Supports two entry shapes:

  * **Request entries** – bounded stream accumulation with a buffer, caller info, and optional timer.
  * **Stream entries** – long-lived subscriptions with a subscriber pid, monitor ref, and opaque subscription ref.
  """

  # ---------------------------------------------------------------------------
  # Initialization
  # ---------------------------------------------------------------------------

  def initialize do
    table_ref = :ets.new(:message_subscriptions, [:set, :public])
    :ets.insert(table_ref, {:message_request_ids, 1})
    table_ref
  end

  # ---------------------------------------------------------------------------
  # Request ID allocation
  # ---------------------------------------------------------------------------

  @doc """
  Allocates the next request id from the ETS counter without registering a subscription.
  """
  def allocate_request_id(table_ref) do
    [message_request_ids: next_request_id] = :ets.lookup(table_ref, :message_request_ids)
    :ets.update_counter(table_ref, :message_request_ids, {2, 1})
    next_request_id
  end

  # ---------------------------------------------------------------------------
  # Legacy subscription helpers (kept for backward compatibility)
  # ---------------------------------------------------------------------------

  def subscribe_by_request_id(table_ref, pid) do
    next_request_id = allocate_request_id(table_ref)
    :ets.insert(table_ref, {to_string(next_request_id), pid})
    next_request_id
  end

  def subscribe_by_modules(table_ref, modules, pid) when is_list(modules) do
    Enum.each(modules, &:ets.insert(table_ref, {&1, pid}))
    :ok
  end

  def subscribe_by_custom_id(table_ref, custom_id, pid) do
    :ets.insert(table_ref, {to_string(custom_id), pid})
  end

  # ---------------------------------------------------------------------------
  # Rich entry registration
  # ---------------------------------------------------------------------------

  @doc """
  Registers a bounded-stream request entry in ETS.

  Stores a map with `type: :request`, the caller pid, the GenServer `from` reference,
  an empty accumulation buffer, an optional timer reference, and the request module.
  """
  def register_request(table_ref, request_id, caller, from, timer_ref, request_module) do
    entry = %{
      type: :request,
      caller: caller,
      from: from,
      buffer: [],
      timer_ref: timer_ref,
      request_module: request_module
    }

    :ets.insert(table_ref, {to_string(request_id), entry})
    :ok
  end

  @doc """
  Registers a long-lived stream subscription entry in ETS.

  Stores a map with `type: :stream`, the subscriber pid, a monitor reference,
  an opaque subscription reference, and the request module.
  """
  def register_stream(table_ref, request_id, subscriber, monitor_ref, subscription_ref, request_module) do
    entry = %{
      type: :stream,
      subscriber: subscriber,
      monitor_ref: monitor_ref,
      subscription_ref: subscription_ref,
      request_module: request_module
    }

    :ets.insert(table_ref, {to_string(request_id), entry})
    :ok
  end

  # ---------------------------------------------------------------------------
  # Buffer accumulation
  # ---------------------------------------------------------------------------

  @doc """
  Appends a response to the buffer of a request entry in ETS.

  Returns `{:ok, updated_entry}` on success or `{:error, :missing_subscription}` if the key
  is not found.
  """
  def append_response(table_ref, request_id, response) do
    key = to_string(request_id)

    case :ets.lookup(table_ref, key) do
      [{^key, %{type: :request, buffer: buffer} = entry}] ->
        updated_entry = %{entry | buffer: buffer ++ [response]}
        :ets.insert(table_ref, {key, updated_entry})
        {:ok, updated_entry}

      _ ->
        {:error, :missing_subscription}
    end
  end

  # ---------------------------------------------------------------------------
  # Request completion
  # ---------------------------------------------------------------------------

  @doc """
  Completes a bounded-stream request by returning its accumulated buffer and
  deleting the ETS entry.

  Returns `{:ok, buffer}` on success or `{:error, :missing_subscription}` if the key
  is not found.
  """
  def complete_request(table_ref, request_id) do
    key = to_string(request_id)

    case :ets.lookup(table_ref, key) do
      [{^key, %{type: :request, buffer: buffer}}] ->
        :ets.delete(table_ref, key)
        {:ok, buffer}

      _ ->
        {:error, :missing_subscription}
    end
  end

  # ---------------------------------------------------------------------------
  # Subscription removal
  # ---------------------------------------------------------------------------

  @doc """
  Removes any subscription entry by its key.
  """
  def remove_subscription(table_ref, key) do
    :ets.delete(table_ref, to_string(key))
    :ok
  end

  # ---------------------------------------------------------------------------
  # Lookup helpers
  # ---------------------------------------------------------------------------

  @doc """
  Looks up a subscription entry by key.

  Returns `{:ok, value}` where value is either a pid (legacy entries) or a full
  entry map (rich entries), or `{:error, :missing_subscription}` if not found.
  """
  def lookup(table_ref, key) do
    case :ets.lookup(table_ref, key) do
      [{_, value}] ->
        {:ok, value}

      _ ->
        {:error, :missing_subscription}
    end
  end

  @doc """
  Looks up a stream subscription entry by its opaque subscription reference.

  Returns `{:ok, key, entry}` on success or `{:error, :missing_subscription}` if no
  entry matches.
  """
  def lookup_by_subscription_ref(table_ref, subscription_ref) do
    # Match pattern: {key, %{type: :stream, subscription_ref: subscription_ref, ...}}
    # We use :ets.match_object with a guard-style approach via :ets.foldl
    result =
      :ets.foldl(
        fn
          {key, %{type: :stream, subscription_ref: ^subscription_ref} = entry}, _acc ->
            {:found, key, entry}

          _other, acc ->
            acc
        end,
        :not_found,
        table_ref
      )

    case result do
      {:found, key, entry} -> {:ok, key, entry}
      :not_found -> {:error, :missing_subscription}
    end
  end

  def reverse_lookup(table_ref, pid) do
    spec = {List.to_atom(~c"$1"), pid}

    # NOTE: this could match to multiple entries if the same pid is
    # tied to multiple requests, we return the first element returned by match/2
    case :ets.match(table_ref, spec) do
      [[key] | _] ->
        {:ok, key}

      _ ->
        {:error, :missing_subscription}
    end
  end
end
