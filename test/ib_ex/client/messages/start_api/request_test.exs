defmodule IbEx.Client.Messages.StartApi.RequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.StartApi.Request
  alias IbEx.Client.Messages.Requests
  alias IbEx.Client.Protocols.Traceable

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

  describe "to_protobuf/1" do
    test "encodes the request to a protobuf binary that decodes to the correct fields" do
      {:ok, msg} = Request.new(client_id: 1)

      payload = Request.to_protobuf(msg)

      decoded = IbEx.Client.Proto.Protobuf.StartApiRequest.decode(payload)
      assert decoded.client_id == 1
      assert decoded.optional_capabilities == nil
    end

    test "includes optional_capabilities when present" do
      {:ok, msg} = Request.new(client_id: 0, optional_capabilities: "SOME_CAP")

      payload = Request.to_protobuf(msg)

      decoded = IbEx.Client.Proto.Protobuf.StartApiRequest.decode(payload)
      assert decoded.client_id == 0
      assert decoded.optional_capabilities == "SOME_CAP"
    end
  end

  describe "encode_request/1" do
    test "produces a binary with 4-byte wire_id header followed by protobuf payload" do
      {:ok, msg} = Request.new(client_id: 0)

      assert {:ok, encoded} = Requests.encode_request(msg)

      # msg_id=71, wire_id=71+200=271
      <<wire_id::big-integer-size(32), payload::binary>> = encoded
      assert wire_id == 271

      decoded = IbEx.Client.Proto.Protobuf.StartApiRequest.decode(payload)
      assert decoded.client_id == 0
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      {:ok, msg} = Request.new([])

      assert Traceable.to_s(msg) == "--> StartAPI{id: 71, version: 2, client_id: 0, opt_capabilities: []}"
    end
  end
end
