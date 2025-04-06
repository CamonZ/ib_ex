defmodule IbEx.Client.Messages.News.HistoricalNewsEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.HistoricalNewsEnd
  alias IbEx.Client.Protocols.Traceable

  describe "from_fields/1" do
    test "creates the message" do
      {:ok, msg} = HistoricalNewsEnd.from_fields(["90001", "1"])

      assert msg.request_id == "90001"
      assert msg.has_more == true
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == HistoricalNewsEnd.from_fields(["123"])
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      assert Traceable.to_s(%HistoricalNewsEnd{request_id: "90001", has_more: true}) ==
               "<-- %News.HistoricalNewsEnd{request_id: 90001, has_more: true}"
    end
  end
end
