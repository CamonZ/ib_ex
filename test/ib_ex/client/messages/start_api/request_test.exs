defmodule IbEx.Client.Messages.StartApi.RequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.StartApi.Request

  describe "new/1" do
    test "returns a StartApi Request message" do
      assert {:ok, %Request{} = request} = Request.new([])

      assert request.message_id == 71
      assert request.optional_capabilities == []
      assert request.client_id == 0
      assert request.version == 2
    end
  end

  describe "String.Chars" do
    test "to_string/1 returns the binary representation of the message" do
      {:ok, msg} = Request.new([])

      assert to_string(msg) == <<55, 49, 0, 50, 0, 48, 0>>
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = Request.new([])

      assert inspect(msg) == "--> StartAPI{id: 71, version: 2, client_id: 0, opt_capabilities: []}"
    end
  end
end
