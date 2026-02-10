defmodule IbEx.Client.SubscriptionsTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Subscriptions

  setup do
    table_refs = Subscriptions.initialize()
    %{table_refs: table_refs}
  end

  # ---------------------------------------------------------------------------
  # initialize/0
  # ---------------------------------------------------------------------------

  describe "initialize/0" do
    test "returns a map with :subscribers and :responses keys", %{table_refs: table_refs} do
      assert %{subscribers: subscribers, responses: responses} = table_refs
      assert is_reference(subscribers)
      assert is_reference(responses)
    end

    test "seeds the request ID counter at 1", %{table_refs: %{subscribers: subscribers}} do
      assert :ets.lookup(subscribers, :message_request_ids) == [message_request_ids: 1]
    end
  end

  # ---------------------------------------------------------------------------
  # allocate_request_id/1
  # ---------------------------------------------------------------------------

  describe "allocate_request_id/1" do
    test "returns 1 as the first allocated request id", %{table_refs: table_refs} do
      assert Subscriptions.allocate_request_id(table_refs) == 1
    end

    test "returns incrementing integers on successive calls", %{table_refs: table_refs} do
      first = Subscriptions.allocate_request_id(table_refs)
      second = Subscriptions.allocate_request_id(table_refs)
      third = Subscriptions.allocate_request_id(table_refs)

      assert first == 1
      assert second == 2
      assert third == 3
    end

    test "advances the counter without inserting a subscription entry", %{table_refs: table_refs} do
      request_id = Subscriptions.allocate_request_id(table_refs)

      assert Subscriptions.lookup(table_refs, {:request_id, request_id}) == {:error, :missing_subscription}
    end
  end

  # ---------------------------------------------------------------------------
  # register_request/5 + lookup round-trip
  # ---------------------------------------------------------------------------

  describe "register_request/5" do
    test "stores a request entry that can be looked up", %{table_refs: table_refs} do
      req_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, req_id}
      from = {self(), make_ref()}
      timer_ref = make_ref()

      assert :ok = Subscriptions.register_request(table_refs, key, from, timer_ref, SomeRequestModule)

      assert {:ok, entry} = Subscriptions.lookup(table_refs, key)

      assert entry.type == :request
      assert entry.from == from
      assert entry.timer_ref == timer_ref
      assert entry.request_module == SomeRequestModule
      refute Map.has_key?(entry, :buffer)
    end

    test "stores entry with nil timer_ref", %{table_refs: table_refs} do
      req_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, req_id}

      assert :ok = Subscriptions.register_request(table_refs, key, {self(), make_ref()}, nil, SomeMod)

      assert {:ok, entry} = Subscriptions.lookup(table_refs, key)
      assert entry.timer_ref == nil
    end

    test "works with {:global, module} keys", %{table_refs: table_refs} do
      key = {:global, SomeGlobalModule}
      from = {self(), make_ref()}
      timer_ref = make_ref()

      assert :ok = Subscriptions.register_request(table_refs, key, from, timer_ref, SomeGlobalModule)

      assert {:ok, entry} = Subscriptions.lookup(table_refs, key)
      assert entry.type == :request
      assert entry.request_module == SomeGlobalModule
    end

    test "works with {:order_id, integer} keys", %{table_refs: table_refs} do
      key = {:order_id, 42}
      from = {self(), make_ref()}
      timer_ref = make_ref()

      assert :ok = Subscriptions.register_request(table_refs, key, from, timer_ref, SomeOrderModule)

      assert {:ok, entry} = Subscriptions.lookup(table_refs, key)
      assert entry.type == :request
      assert entry.request_module == SomeOrderModule
    end
  end

  # ---------------------------------------------------------------------------
  # register_stream/6
  # ---------------------------------------------------------------------------

  describe "register_stream/6" do
    test "stores a stream entry that can be looked up", %{table_refs: table_refs} do
      request_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, request_id}
      subscriber = self()
      monitor_ref = make_ref()
      subscription_ref = make_ref()

      assert :ok =
               Subscriptions.register_stream(
                 table_refs,
                 key,
                 subscriber,
                 monitor_ref,
                 subscription_ref,
                 StreamModule
               )

      assert {:ok, entry} = Subscriptions.lookup(table_refs, key)

      assert entry.type == :stream
      assert entry.subscriber == subscriber
      assert entry.monitor_ref == monitor_ref
      assert entry.subscription_ref == subscription_ref
      assert entry.request_module == StreamModule
    end
  end

  # ---------------------------------------------------------------------------
  # append_response/3 + get_responses/2
  # ---------------------------------------------------------------------------

  describe "append_response/3" do
    test "accumulates responses into the shared buffer in order", %{table_refs: table_refs} do
      req_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, req_id}
      Subscriptions.register_request(table_refs, key, {self(), make_ref()}, nil, SomeMod)

      assert :ok = Subscriptions.append_response(table_refs, key, :response_a)
      assert {:ok, [:response_a]} = Subscriptions.get_responses(table_refs, key)

      assert :ok = Subscriptions.append_response(table_refs, key, :response_b)
      assert {:ok, [:response_a, :response_b]} = Subscriptions.get_responses(table_refs, key)

      assert :ok = Subscriptions.append_response(table_refs, key, :response_c)
      assert {:ok, [:response_a, :response_b, :response_c]} = Subscriptions.get_responses(table_refs, key)
    end

    test "stores responses in the shared buffer even without subscribers", %{table_refs: table_refs} do
      key = {:request_id, 999}

      assert :ok = Subscriptions.append_response(table_refs, key, :response)
      assert {:ok, [:response]} = Subscriptions.get_responses(table_refs, key)
    end
  end

  describe "get_responses/2" do
    test "returns empty list when no responses have been buffered", %{table_refs: table_refs} do
      assert {:ok, []} = Subscriptions.get_responses(table_refs, {:request_id, 999})
    end
  end

  describe "clear_responses/2" do
    test "removes the shared buffer for a key", %{table_refs: table_refs} do
      key = {:request_id, 1}
      Subscriptions.append_response(table_refs, key, :response)

      assert {:ok, [:response]} = Subscriptions.get_responses(table_refs, key)
      assert :ok = Subscriptions.clear_responses(table_refs, key)
      assert {:ok, []} = Subscriptions.get_responses(table_refs, key)
    end
  end

  # ---------------------------------------------------------------------------
  # remove_subscription/2
  # ---------------------------------------------------------------------------

  describe "remove_subscription/2" do
    test "removes a request entry and its shared responses", %{table_refs: table_refs} do
      req_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, req_id}
      Subscriptions.register_request(table_refs, key, {self(), make_ref()}, nil, SomeMod)
      Subscriptions.append_response(table_refs, key, :resp)

      assert :ok = Subscriptions.remove_subscription(table_refs, key)
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_refs, key)
      assert {:ok, []} = Subscriptions.get_responses(table_refs, key)
    end

    test "removes a stream entry", %{table_refs: table_refs} do
      request_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, request_id}
      Subscriptions.register_stream(table_refs, key, self(), make_ref(), make_ref(), StreamMod)

      assert :ok = Subscriptions.remove_subscription(table_refs, key)
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_refs, key)
    end

    test "returns :ok even if key does not exist", %{table_refs: table_refs} do
      assert :ok = Subscriptions.remove_subscription(table_refs, {:request_id, 42})
    end
  end

  # ---------------------------------------------------------------------------
  # remove_entry/3
  # ---------------------------------------------------------------------------

  describe "remove_entry/3" do
    test "clears shared responses when last subscriber is removed", %{table_refs: table_refs} do
      req_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, req_id}
      from = {self(), make_ref()}
      timer_ref = make_ref()

      Subscriptions.register_request(table_refs, key, from, timer_ref, SomeMod)
      Subscriptions.append_response(table_refs, key, :resp)

      entry = %{type: :request, from: from, timer_ref: timer_ref, request_module: SomeMod}
      assert :ok = Subscriptions.remove_entry(table_refs, key, entry)

      assert {:error, :missing_subscription} = Subscriptions.lookup(table_refs, key)
      assert {:ok, []} = Subscriptions.get_responses(table_refs, key)
    end

    test "preserves shared responses when other subscribers remain", %{table_refs: table_refs} do
      key = {:order_id, 42}

      # Register two subscribers
      stream_sub_ref = make_ref()
      stream_monitor_ref = make_ref()
      Subscriptions.register_stream(table_refs, key, self(), stream_monitor_ref, stream_sub_ref, StreamMod)

      from = {self(), make_ref()}
      timer_ref = make_ref()
      Subscriptions.register_request(table_refs, key, from, timer_ref, ReqMod)

      Subscriptions.append_response(table_refs, key, :resp)

      # Remove only the request entry
      request_entry = %{type: :request, from: from, timer_ref: timer_ref, request_module: ReqMod}
      Subscriptions.remove_entry(table_refs, key, request_entry)

      # Stream subscriber still exists, responses preserved
      assert {:ok, [%{type: :stream}]} = Subscriptions.lookup_all(table_refs, key)
      assert {:ok, [:resp]} = Subscriptions.get_responses(table_refs, key)
    end
  end

  # ---------------------------------------------------------------------------
  # lookup_by_subscription_ref/2
  # ---------------------------------------------------------------------------

  describe "lookup_by_subscription_ref/2" do
    test "finds a stream entry by its subscription_ref", %{table_refs: table_refs} do
      request_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, request_id}
      subscription_ref = make_ref()

      Subscriptions.register_stream(table_refs, key, self(), make_ref(), subscription_ref, StreamMod)

      assert {:ok, found_key, entry} = Subscriptions.lookup_by_subscription_ref(table_refs, subscription_ref)
      assert found_key == key
      assert entry.type == :stream
      assert entry.subscription_ref == subscription_ref
      assert entry.request_module == StreamMod
    end

    test "returns error when no entry matches the subscription_ref", %{table_refs: table_refs} do
      assert {:error, :missing_subscription} =
               Subscriptions.lookup_by_subscription_ref(table_refs, make_ref())
    end

    test "does not match request entries", %{table_refs: table_refs} do
      req_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, req_id}
      Subscriptions.register_request(table_refs, key, {self(), make_ref()}, nil, SomeMod)

      assert {:error, :missing_subscription} =
               Subscriptions.lookup_by_subscription_ref(table_refs, make_ref())
    end
  end

  # ---------------------------------------------------------------------------
  # lookup/2
  # ---------------------------------------------------------------------------

  describe "lookup/2" do
    test "returns full entry map for rich request entries", %{table_refs: table_refs} do
      req_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, req_id}
      Subscriptions.register_request(table_refs, key, {self(), make_ref()}, nil, SomeMod)

      assert {:ok, %{type: :request}} = Subscriptions.lookup(table_refs, key)
    end

    test "returns full entry map for stream entries", %{table_refs: table_refs} do
      request_id = Subscriptions.allocate_request_id(table_refs)
      key = {:request_id, request_id}
      Subscriptions.register_stream(table_refs, key, self(), make_ref(), make_ref(), StreamMod)

      assert {:ok, %{type: :stream}} = Subscriptions.lookup(table_refs, key)
    end

    test "returns error for missing key", %{table_refs: table_refs} do
      assert {:error, :missing_subscription} = Subscriptions.lookup(table_refs, "nonexistent")
    end
  end
end
