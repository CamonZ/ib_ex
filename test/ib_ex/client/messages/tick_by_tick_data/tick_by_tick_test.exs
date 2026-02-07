defmodule IbEx.Client.Messages.TickByTickData.TickByTickTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.TickByTickData.TickByTick
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      msg = %TickByTick{request_id: "1", tick: nil}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
