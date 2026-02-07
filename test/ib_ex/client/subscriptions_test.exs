defmodule IbEx.Client.SubscriptionsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Subscriptions

  setup do
    table_ref = Subscriptions.initialize()
    %{table_ref: table_ref}
  end

  # ---------------------------------------------------------------------------
  # allocate_request_id/1
  # ---------------------------------------------------------------------------

  describe "allocate_request_id/1" do
    test "returns 1 as the first allocated request id", %{table_ref: table_ref} do
      assert Subscriptions.allocate_request_id(table_ref) == 1
    end

    test "returns incrementing integers on successive calls", %{table_ref: table_ref} do
      first = Subscriptions.allocate_request_id(table_ref)
      second = Subscriptions.allocate_request_id(table_ref)
      third = Subscriptions.allocate_request_id(table_ref)

      assert first == 1
      assert second == 2
      assert third == 3
    end

    test "advances the counter without inserting a subscription entry", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)

      assert Subscriptions.lookup(table_ref, to_string(request_id)) == {:error, :missing_subscription}
    end
  end

  # ---------------------------------------------------------------------------
  # register_request/6 + lookup round-trip
  # ---------------------------------------------------------------------------

  describe "register_request/6" do
    test "stores a request entry that can be looked up", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      caller = self()
      from = {self(), make_ref()}
      timer_ref = make_ref()

      assert :ok = Subscriptions.register_request(table_ref, request_id, caller, from, timer_ref, SomeRequestModule)

      assert {:ok, entry} = Subscriptions.lookup(table_ref, to_string(request_id))

      assert entry.type == :request
      assert entry.caller == caller
      assert entry.from == from
      assert entry.buffer == []
      assert entry.timer_ref == timer_ref
      assert entry.request_module == SomeRequestModule
    end

    test "stores entry with nil timer_ref", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)

      assert :ok = Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      assert {:ok, entry} = Subscriptions.lookup(table_ref, to_string(request_id))
      assert entry.timer_ref == nil
    end
  end

  # ---------------------------------------------------------------------------
  # register_stream/6
  # ---------------------------------------------------------------------------

  describe "register_stream/6" do
    test "stores a stream entry that can be looked up", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      subscriber = self()
      monitor_ref = make_ref()
      subscription_ref = make_ref()

      assert :ok =
               Subscriptions.register_stream(
                 table_ref,
                 request_id,
                 subscriber,
                 monitor_ref,
                 subscription_ref,
                 StreamModule
               )

      assert {:ok, entry} = Subscriptions.lookup(table_ref, to_string(request_id))

      assert entry.type == :stream
      assert entry.subscriber == subscriber
      assert entry.monitor_ref == monitor_ref
      assert entry.subscription_ref == subscription_ref
      assert entry.request_module == StreamModule
    end
  end

  # ---------------------------------------------------------------------------
  # append_response/3
  # ---------------------------------------------------------------------------

  describe "append_response/3" do
    test "accumulates responses into the buffer in order", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      assert {:ok, entry1} = Subscriptions.append_response(table_ref, request_id, :response_a)
      assert entry1.buffer == [:response_a]

      assert {:ok, entry2} = Subscriptions.append_response(table_ref, request_id, :response_b)
      assert entry2.buffer == [:response_a, :response_b]

      assert {:ok, entry3} = Subscriptions.append_response(table_ref, request_id, :response_c)
      assert entry3.buffer == [:response_a, :response_b, :response_c]
    end

    test "returns error for non-existent key", %{table_ref: table_ref} do
      assert {:error, :missing_subscription} = Subscriptions.append_response(table_ref, 999, :response)
    end

    test "returns error when entry is a stream (not a request)", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_stream(table_ref, request_id, self(), make_ref(), make_ref(), StreamMod)

      assert {:error, :missing_subscription} = Subscriptions.append_response(table_ref, request_id, :response)
    end
  end

  # ---------------------------------------------------------------------------
  # complete_request/2
  # ---------------------------------------------------------------------------

  describe "complete_request/2" do
    test "returns accumulated buffer and deletes the entry", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      Subscriptions.append_response(table_ref, request_id, :resp_1)
      Subscriptions.append_response(table_ref, request_id, :resp_2)

      assert {:ok, buffer} = Subscriptions.complete_request(table_ref, request_id)
      assert buffer == [:resp_1, :resp_2]

      # Entry should be deleted
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, to_string(request_id))
    end

    test "returns empty buffer when no responses were appended", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      assert {:ok, buffer} = Subscriptions.complete_request(table_ref, request_id)
      assert buffer == []
    end

    test "returns error for non-existent key", %{table_ref: table_ref} do
      assert {:error, :missing_subscription} = Subscriptions.complete_request(table_ref, 999)
    end

    test "returns error when called twice (entry already deleted)", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      assert {:ok, []} = Subscriptions.complete_request(table_ref, request_id)
      assert {:error, :missing_subscription} = Subscriptions.complete_request(table_ref, request_id)
    end
  end

  # ---------------------------------------------------------------------------
  # remove_subscription/2
  # ---------------------------------------------------------------------------

  describe "remove_subscription/2" do
    test "removes a request entry", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      assert :ok = Subscriptions.remove_subscription(table_ref, request_id)
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, to_string(request_id))
    end

    test "removes a stream entry", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_stream(table_ref, request_id, self(), make_ref(), make_ref(), StreamMod)

      assert :ok = Subscriptions.remove_subscription(table_ref, request_id)
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, to_string(request_id))
    end

    test "returns :ok even if key does not exist", %{table_ref: table_ref} do
      assert :ok = Subscriptions.remove_subscription(table_ref, 42)
    end
  end

  # ---------------------------------------------------------------------------
  # lookup_by_subscription_ref/2
  # ---------------------------------------------------------------------------

  describe "lookup_by_subscription_ref/2" do
    test "finds a stream entry by its subscription_ref", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      subscription_ref = make_ref()

      Subscriptions.register_stream(table_ref, request_id, self(), make_ref(), subscription_ref, StreamMod)

      assert {:ok, key, entry} = Subscriptions.lookup_by_subscription_ref(table_ref, subscription_ref)
      assert key == to_string(request_id)
      assert entry.type == :stream
      assert entry.subscription_ref == subscription_ref
      assert entry.request_module == StreamMod
    end

    test "returns error when no entry matches the subscription_ref", %{table_ref: table_ref} do
      assert {:error, :missing_subscription} =
               Subscriptions.lookup_by_subscription_ref(table_ref, make_ref())
    end

    test "does not match request entries", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      assert {:error, :missing_subscription} =
               Subscriptions.lookup_by_subscription_ref(table_ref, make_ref())
    end
  end

  # ---------------------------------------------------------------------------
  # lookup/2 backward compatibility
  # ---------------------------------------------------------------------------

  describe "lookup/2" do
    test "returns pid for legacy entries created by subscribe_by_request_id", %{table_ref: table_ref} do
      request_id = Subscriptions.subscribe_by_request_id(table_ref, self())

      assert {:ok, pid} = Subscriptions.lookup(table_ref, to_string(request_id))
      assert pid == self()
    end

    test "returns full entry map for rich request entries", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_request(table_ref, request_id, self(), {self(), make_ref()}, nil, SomeMod)

      assert {:ok, %{type: :request}} = Subscriptions.lookup(table_ref, to_string(request_id))
    end

    test "returns full entry map for stream entries", %{table_ref: table_ref} do
      request_id = Subscriptions.allocate_request_id(table_ref)
      Subscriptions.register_stream(table_ref, request_id, self(), make_ref(), make_ref(), StreamMod)

      assert {:ok, %{type: :stream}} = Subscriptions.lookup(table_ref, to_string(request_id))
    end

    test "returns error for missing key", %{table_ref: table_ref} do
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_ref, "nonexistent")
    end
  end

  # ---------------------------------------------------------------------------
  # subscribe_by_request_id/2 still uses allocate_request_id internally
  # ---------------------------------------------------------------------------

  describe "subscribe_by_request_id/2 (legacy)" do
    test "allocates and registers in one step", %{table_ref: table_ref} do
      request_id = Subscriptions.subscribe_by_request_id(table_ref, self())

      assert request_id == 1
      assert {:ok, self()} == Subscriptions.lookup(table_ref, to_string(request_id))
    end

    test "shares the counter with allocate_request_id", %{table_ref: table_ref} do
      allocated_id = Subscriptions.allocate_request_id(table_ref)
      subscribed_id = Subscriptions.subscribe_by_request_id(table_ref, self())

      assert allocated_id == 1
      assert subscribed_id == 2
    end
  end
end
