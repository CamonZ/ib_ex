defmodule IbEx.Client.Messages.Pnl.SinglePositionRequestTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.Pnl.SinglePositionRequest

  @apple_conid "265598"
  @account_id "GU12345678"
  @request_id "70001"

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

  describe "String.Chars implementation" do
    test "to_string/1 returns the correct string representation" do
      msg = %SinglePositionRequest{
        message_id: 94,
        request_id: @request_id,
        account: @account_id,
        conid: @apple_conid,
        model_code: ""
      }

      assert to_string(msg) ==
               <<57, 52, 0, 55, 48, 48, 48, 49, 0, 71, 85, 49, 50, 51, 52, 53, 54, 55, 56, 0, 0, 50, 54, 53, 53, 57, 56,
                 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspect/2 returns the correct string representation" do
      msg = %SinglePositionRequest{
        message_id: 94,
        request_id: @request_id,
        account: @account_id,
        conid: @apple_conid,
        model_code: ""
      }

      assert Inspect.inspect(msg, []) ==
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
