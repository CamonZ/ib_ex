defmodule IbEx.Client.Messages.AccountData.RequestTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.AccountData.Request

  describe "new/2" do
    test "returns an AccountData Request struct" do
      {:ok, %Request{} = request} = Request.new(true)
      assert request.message_id == 6
      assert request.version == 1
      assert request.subscribe == true
      assert is_nil(request.account_code)
    end
  end

  describe "String.Chars" do
    test "to_string/1 returns the binary representation of the message" do
      {:ok, msg} = Request.new(true)
      assert to_string(msg) == <<54, 0, 49, 0, 49, 0, 0>>
    end
  end

  describe "Inspect" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, msg} = Request.new(true)

      # Adjust this expected string to the format that your Inspect implementation produces.
      assert inspect(msg) == "--> AccountUpdates{message_id: 6, subscribe: true, account_code: nil}"
    end
  end
end
