defmodule IbEx.Client.Messages.MatchingSymbols.SymbolSamplesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MatchingSymbols.SymbolSamples
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())

      msg = %SymbolSamples{request_id: "1", contracts: []}

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
