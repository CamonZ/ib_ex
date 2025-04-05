defmodule IbEx.Client.Messages.CurrentTime.RequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.CurrentTime.Request
  alias IbEx.Client.Messages.CurrentTime.Response
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Subscriptions

  describe "new/1" do
    test "returns a CurrentTime.Request message" do
      assert {:ok, %Request{} = request} = Request.new()

      assert request.id == 49
      assert request.version == 1
    end
  end

  describe "String.Chars" do
    test "to_string/1 returns the binary representation of the message" do
      {:ok, msg} = Request.new()
      assert to_string(msg) == <<52, 57, 0, 49, 0>>
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      {:ok, msg} = Request.new()

      assert Traceable.to_s(msg) == "--> %CurrentTime{id: 49, version: 1}"
    end
  end

  describe "Subscribable" do
    test "subscribe/3 subscribes incoming messages with the msg's request id to the given pid" do
      table_ref = Subscriptions.initialize()

      {:ok, msg} = Request.new()

      assert {:ok, ^msg} = Subscribable.subscribe(msg, self(), table_ref)
      assert {:ok, pid} = Subscriptions.lookup(table_ref, Response)

      assert pid == self()
    end
  end
end
