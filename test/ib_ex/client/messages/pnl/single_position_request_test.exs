defmodule IbEx.Client.Messages.Pnl.SinglePositionRequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Pnl.SinglePositionRequest
  alias IbEx.Client.Protocols.Traceable

  @apple_conid "265598"
  @account_id "GU12345678"
  @request_id 70001

  describe "new/4" do
    test "creates a SingleRequest struct with valid inputs" do
      assert {:ok, msg} = SinglePositionRequest.new(@request_id, @account_id, @apple_conid)
      assert msg.message_id == 94
      assert msg.request_id == @request_id
      assert msg.account == @account_id
      assert msg.conid == @apple_conid
      assert msg.model_code == ""
    end
  end

  describe "Traceable" do
    test "to_s/1 returns the correct string representation" do
      msg = %SinglePositionRequest{
        message_id: 94,
        request_id: @request_id,
        account: @account_id,
        conid: @apple_conid,
        model_code: ""
      }

      assert Traceable.to_s(msg) ==
               """
               --> Pnl.SinglePositionRequest{
                 message_id: 94,
                 request_id: 70001,
                 account: GU12345678,
                 model_code: ,
                 conid: 265598
               }
               """
    end
  end
end
