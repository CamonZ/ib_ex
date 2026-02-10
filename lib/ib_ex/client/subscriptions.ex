defmodule IbEx.Client.Subscriptions do
  @moduledoc """
  Handles initialization of the ETS tables used by the client
  to map request ids or structs of a given message responses to the
  process that requested sending the message.

  Uses a "double phone-book" architecture with two separate ETS tables:

  * **Subscribers table** (`:bag`) -- maps correlation keys to subscriber entries.
    Multiple subscribers can exist per key for fan-out dispatch.
  * **Responses table** (`:set`) -- maps correlation keys to a single shared
    response buffer. Responses are stored once per key, not per subscriber.

  Supports two subscriber entry shapes:

  * **Request entries** -- bounded stream callers with a `from` ref, timer, and request module.
  * **Stream entries** -- long-lived subscriptions with a subscriber pid, monitor ref,
    and opaque subscription ref.

  ## Key Shapes

  ETS keys use consistently shaped tagged tuples:

  * `{:request_id, integer()}` -- for req_id-correlated conversations and streams
  * `{:global, module()}` -- for global-correlated conversations (no req_id)
  * `{:order_id, integer()}` -- for order lifecycle conversations

  ## Multi-Subscriber Fan-Out

  When a response arrives, it is stored once in the responses table. All
  subscribers for that key are then looked up from the subscribers table
  and dispatched to individually. This eliminates per-subscriber buffering
  ambiguity and cleanly supports late joiners (e.g. CancelOrder joining an
  existing PlaceOrder lifecycle).
  """

  # ---------------------------------------------------------------------------
  # Table references
  # ---------------------------------------------------------------------------

  @type table_refs :: %{subscribers: :ets.tid(), responses: :ets.tid()}

  # ---------------------------------------------------------------------------
  # Initialization
  # ---------------------------------------------------------------------------

  @doc """
  Creates two ETS tables: one for subscribers (`:bag`) and one for shared
  response buffers (`:set`). Returns a map with both table references.

  Also seeds the request ID counter in the subscribers table.
  """
  @spec initialize() :: table_refs()
  def initialize do
    subscribers = :ets.new(:message_subscriptions, [:bag, :public])
    responses = :ets.new(:message_responses, [:set, :public])
    :ets.insert(subscribers, {:message_request_ids, 1})
    %{subscribers: subscribers, responses: responses}
  end

  # ---------------------------------------------------------------------------
  # Request ID allocation
  # ---------------------------------------------------------------------------

  @doc """
  Allocates the next request id from the ETS counter without registering a subscription.
  """
  def allocate_request_id(%{subscribers: subscribers}) do
    [message_request_ids: next_request_id] = :ets.lookup(subscribers, :message_request_ids)
    :ets.delete(subscribers, :message_request_ids)
    :ets.insert(subscribers, {:message_request_ids, next_request_id + 1})
    next_request_id
  end

  # ---------------------------------------------------------------------------
  # Legacy subscription helpers
  # ---------------------------------------------------------------------------

  def subscribe_by_modules(%{subscribers: subscribers}, modules, pid) when is_list(modules) do
    Enum.each(modules, &:ets.insert(subscribers, {&1, pid}))
    :ok
  end

  # ---------------------------------------------------------------------------
  # Rich entry registration
  # ---------------------------------------------------------------------------

  @doc """
  Registers a bounded-stream request entry in the subscribers table.

  Stores a map with `type: :request`, the GenServer `from` reference,
  a timer reference, and the request module. No per-subscriber buffer --
  responses are stored in the shared responses table.

  The ETS key is the tagged tuple passed as `key` (e.g. `{:request_id, 1}` or `{:global, Module}`).
  """
  def register_request(%{subscribers: subscribers}, key, from, timer_ref, request_module) when is_tuple(key) do
    entry = %{
      type: :request,
      from: from,
      timer_ref: timer_ref,
      request_module: request_module
    }

    :ets.insert(subscribers, {key, entry})
    :ok
  end

  @doc """
  Registers a long-lived stream subscription entry in the subscribers table.

  Stores a map with `type: :stream`, the subscriber pid, a monitor reference,
  an opaque subscription reference, and the request module.

  The ETS key is the tagged tuple passed as `key` (e.g. `{:request_id, 1}`).
  """
  def register_stream(%{subscribers: subscribers}, key, subscriber, monitor_ref, subscription_ref, request_module)
      when is_tuple(key) do
    entry = %{
      type: :stream,
      subscriber: subscriber,
      monitor_ref: monitor_ref,
      subscription_ref: subscription_ref,
      request_module: request_module
    }

    :ets.insert(subscribers, {key, entry})
    :ok
  end

  # ---------------------------------------------------------------------------
  # Shared response buffer
  # ---------------------------------------------------------------------------

  @doc """
  Appends a response to the shared response buffer for a correlation key.

  Responses are stored once per key in the responses table, regardless of
  how many subscribers exist for that key.

  Returns `:ok` on success.
  """
  def append_response(%{responses: responses}, key, response) when is_tuple(key) do
    case :ets.lookup(responses, key) do
      [{^key, buffer}] ->
        :ets.insert(responses, {key, buffer ++ [response]})

      [] ->
        :ets.insert(responses, {key, [response]})
    end

    :ok
  end

  @doc """
  Returns the shared response buffer for a correlation key.

  Returns `{:ok, buffer}` on success or `{:ok, []}` if no responses
  have been buffered yet.
  """
  def get_responses(%{responses: responses}, key) when is_tuple(key) do
    case :ets.lookup(responses, key) do
      [{^key, buffer}] -> {:ok, buffer}
      [] -> {:ok, []}
    end
  end

  @doc """
  Clears the shared response buffer for a correlation key.

  Should be called when no more subscribers need the buffered responses.
  """
  def clear_responses(%{responses: responses}, key) when is_tuple(key) do
    :ets.delete(responses, key)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Subscription removal
  # ---------------------------------------------------------------------------

  @doc """
  Removes all subscriber entries for a given key and clears the shared
  response buffer.
  """
  def remove_subscription(%{subscribers: subscribers, responses: responses}, key) when is_tuple(key) do
    :ets.delete(subscribers, key)
    :ets.delete(responses, key)
    :ok
  end

  @doc """
  Removes a specific subscriber entry by key and entry value.

  In a `:bag` table, this removes only the matching entry, leaving other
  entries for the same key intact. If no subscribers remain for the key
  after removal, the shared response buffer is also cleared.
  """
  def remove_entry(%{subscribers: subscribers, responses: responses} = _table_refs, key, entry) when is_tuple(key) do
    :ets.delete_object(subscribers, {key, entry})

    # Clean up responses if no more subscribers for this key
    case :ets.lookup(subscribers, key) do
      [] -> :ets.delete(responses, key)
      _ -> :ok
    end

    :ok
  end

  # ---------------------------------------------------------------------------
  # Lookup helpers
  # ---------------------------------------------------------------------------

  @doc """
  Looks up a subscriber entry by key.

  Returns `{:ok, value}` where value is either a pid (legacy entries) or a full
  entry map (rich entries), or `{:error, :missing_subscription}` if not found.

  When multiple entries exist for the same key, returns the first one found.
  Use `lookup_all/2` to retrieve all entries for fan-out dispatch.
  """
  def lookup(%{subscribers: subscribers}, key) do
    case :ets.lookup(subscribers, key) do
      [{_, value} | _] ->
        {:ok, value}

      _ ->
        {:error, :missing_subscription}
    end
  end

  @doc """
  Looks up all subscriber entries for a given key.

  Returns `{:ok, entries}` where entries is a list of entry maps,
  or `{:error, :missing_subscription}` if no entries exist for the key.

  Used for fan-out dispatch where multiple subscribers share the same key.
  """
  def lookup_all(%{subscribers: subscribers}, key) do
    case :ets.lookup(subscribers, key) do
      [] ->
        {:error, :missing_subscription}

      results ->
        {:ok, Enum.map(results, fn {_key, entry} -> entry end)}
    end
  end

  @doc """
  Looks up a stream subscriber entry by its opaque subscription reference.

  Returns `{:ok, key, entry}` on success or `{:error, :missing_subscription}` if no
  entry matches.
  """
  def lookup_by_subscription_ref(%{subscribers: subscribers}, subscription_ref) do
    result =
      :ets.foldl(
        fn
          {key, %{type: :stream, subscription_ref: ^subscription_ref} = entry}, _acc ->
            {:found, key, entry}

          _other, acc ->
            acc
        end,
        :not_found,
        subscribers
      )

    case result do
      {:found, key, entry} -> {:ok, key, entry}
      :not_found -> {:error, :missing_subscription}
    end
  end

  @doc """
  Looks up a stream subscriber entry by its monitor reference.

  Returns `{:ok, key, entry}` on success or `{:error, :missing_subscription}` if no
  entry matches.
  """
  def lookup_by_monitor_ref(%{subscribers: subscribers}, monitor_ref) do
    result =
      :ets.foldl(
        fn
          {key, %{type: :stream, monitor_ref: ^monitor_ref} = entry}, _acc ->
            {:found, key, entry}

          _other, acc ->
            acc
        end,
        :not_found,
        subscribers
      )

    case result do
      {:found, key, entry} -> {:ok, key, entry}
      :not_found -> {:error, :missing_subscription}
    end
  end

  def reverse_lookup(%{subscribers: subscribers}, pid) do
    spec = {List.to_atom(~c"$1"), pid}

    # NOTE: this could match to multiple entries if the same pid is
    # tied to multiple requests, we return the first element returned by match/2
    case :ets.match(subscribers, spec) do
      [[key] | _] ->
        {:ok, key}

      _ ->
        {:error, :missing_subscription}
    end
  end
end
