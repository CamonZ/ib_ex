defmodule IbEx.Client.Messages.Ids.RequestTest do
  use ExUnit.Case
  alias IbEx.Client.Messages.Ids.Request

  describe "new/1" do
    test "creates a new Request with a valid message id" do
      assert {:ok, request} = Request.new(1)
      assert request.message_id == 8
      assert request.version == 1
      assert request.number_of_ids == 1
    end

    test "asserts that the message is implemented" do
      assert {:ok, %Request{}} = Request.new()
    end
  end

  describe "String.Chars implementation" do
    test "converts the Request to a binary correctly" do
      {:ok, request} = Request.new(1)
      assert to_string(request) == <<56, 0, 49, 0, 49, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspect/2 returns a human-readable version of the message" do
      {:ok, request} = Request.new(2)
      assert inspect(request) == "--> Ids{number_of_ids: 2}"
    end
  end
end
