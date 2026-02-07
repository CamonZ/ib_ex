defmodule IbEx.Client.Messages.ResponsesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Responses

  @protobuf_offset 200

  describe "parse/3 with :connecting status" do
    test "parses InitConnection response in legacy text format" do
      str = "213\x0020240605 17:25:52 Central European Standard Time\x00"

      assert {:ok, msg} = Responses.parse(str, :connecting, false)

      assert %IbEx.Client.Messages.InitConnection.Response{} = msg
      assert msg.server_version == 213
      assert msg.connection_timestamp == ~N[2024-06-05 17:25:52]
    end
  end

  describe "parse/3 with :connected status (protobuf)" do
    test "extracts msg_id from 4-byte big-endian integer and subtracts 200" do
      # ManagedAccounts has msg_id=15, wire_id=15+200=215
      proto_payload =
        %IbEx.Client.Proto.Protobuf.ManagedAccounts{accounts_list: "DU123456"}
        |> Protobuf.encode()

      wire_msg = <<15 + @protobuf_offset::big-integer-size(32), proto_payload::binary>>

      assert {:ok, msg} = Responses.parse(wire_msg, :connected, false)

      assert %IbEx.Client.Proto.Protobuf.ManagedAccounts{} = msg
      assert msg.accounts_list == "DU123456"
    end

    test "parses NextValidId protobuf message" do
      # NextValidId has msg_id=9, wire_id=9+200=209
      proto_payload =
        %IbEx.Client.Proto.Protobuf.NextValidId{order_id: 42}
        |> Protobuf.encode()

      wire_msg = <<9 + @protobuf_offset::big-integer-size(32), proto_payload::binary>>

      assert {:ok, msg} = Responses.parse(wire_msg, :connected, false)

      assert %IbEx.Client.Proto.Protobuf.NextValidId{} = msg
      assert msg.order_id == 42
    end

    test "parses ErrorMessage protobuf as Error when id != -1" do
      proto_payload =
        %IbEx.Client.Proto.Protobuf.ErrorMessage{
          id: 1,
          error_code: 200,
          error_msg: "No security definition has been found"
        }
        |> Protobuf.encode()

      wire_msg = <<4 + @protobuf_offset::big-integer-size(32), proto_payload::binary>>

      assert {:ok, msg} = Responses.parse(wire_msg, :connected, false)

      assert %IbEx.Client.Types.Error{} = msg
      assert msg.id == 1
      assert msg.code == 200
      assert msg.message == "No security definition has been found"
    end

    test "parses ErrorMessage protobuf as Info when id == -1" do
      proto_payload =
        %IbEx.Client.Proto.Protobuf.ErrorMessage{
          id: -1,
          error_code: 2104,
          error_msg: "Market data farm connection is OK"
        }
        |> Protobuf.encode()

      wire_msg = <<4 + @protobuf_offset::big-integer-size(32), proto_payload::binary>>

      assert {:ok, msg} = Responses.parse(wire_msg, :connected, false)

      assert %IbEx.Client.Types.Info{} = msg
      assert msg.id == -1
      assert msg.code == 2104
      assert msg.message == "Market data farm connection is OK"
    end

    test "decodes BondContractData (msg_id=18) as ContractData proto" do
      proto_payload =
        %IbEx.Client.Proto.Protobuf.ContractData{req_id: 5}
        |> Protobuf.encode()

      wire_msg = <<18 + @protobuf_offset::big-integer-size(32), proto_payload::binary>>

      assert {:ok, msg} = Responses.parse(wire_msg, :connected, false)
      assert %IbEx.Client.Proto.Protobuf.ContractData{} = msg
      assert msg.req_id == 5
    end

    test "decodes PortfolioValue protobuf message via generic decoder" do
      # msg_id=7, wire_id=7+200=207
      proto_payload =
        %IbEx.Client.Proto.Protobuf.PortfolioValue{}
        |> Protobuf.encode()

      wire_msg = <<7 + @protobuf_offset::big-integer-size(32), proto_payload::binary>>

      assert {:ok, msg} = Responses.parse(wire_msg, :connected, false)
      assert %IbEx.Client.Proto.Protobuf.PortfolioValue{} = msg
    end

    @tag capture_log: true
    test "returns :unexpected_error for unknown msg_ids" do
      # msg_id=999 is not in any lookup table
      wire_msg = <<999 + @protobuf_offset::big-integer-size(32), "some_payload">>

      assert {:error, :unexpected_error} = Responses.parse(wire_msg, :connected, false)
    end
  end
end
