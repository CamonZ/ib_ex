defmodule IbEx.Client.Messages.Ids.RequestTest do
  use ExUnit.Case, async: true
  alias IbEx.Client.Messages.Ids.Request

  describe "new/1" do
    test "creates a new Request with a valid message id" do
      assert {:ok, request} = Request.new()
      assert request.message_id == 8
      assert request.version == 1
    end

    test "asserts that the message is implemented" do
      assert {:ok, %Request{}} = Request.new()
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a binary correctly" do
      {:ok, request} = Request.new()
      assert to_string(request) == <<56, 0, 49, 0, 49, 0>>
    end
  end

  describe "inspect/2" do
    test "returns a human-readable version of the message" do
      {:ok, request} = Request.new()
      assert inspect(request) == "--> Ids.Request{number_of_ids: 1}"
    end
  end
end
