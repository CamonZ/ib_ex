defmodule IbEx.Client.Messages.Pnl.AllPositionsRequestTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.Pnl.AllPositionsRequest

  @account_id "GU12345678"
  @request_id "70001"

  describe "new/4" do
    test "creates a SingleRequest struct with valid inputs" do
      assert {:ok, msg} = AllPositionsRequest.new(@request_id, @account_id)
      assert msg.message_id == 92
      assert msg.request_id == @request_id
      assert msg.account == @account_id
      assert msg.model_code == ""
    end
  end

  describe "String.Chars implementation" do
    test "to_string/1 returns the correct string representation" do
      msg = %AllPositionsRequest{
        message_id: 92,
        request_id: @request_id,
        account: @account_id,
        model_code: ""
      }

      assert to_string(msg) ==
               <<57, 50, 0, 55, 48, 48, 48, 49, 0, 71, 85, 49, 50, 51, 52, 53, 54, 55, 56, 0, 0>>
    end
  end

  describe "Inspect implementation" do
    test "inspect/2 returns the correct string representation" do
      msg = %AllPositionsRequest{
        message_id: 92,
        request_id: @request_id,
        account: @account_id,
        model_code: ""
      }

      assert Inspect.inspect(msg, []) ==
               """
               --> Pnl.AllPositionsRequest{
                 id: 92,
                 request_id: 70001,
                 account: GU12345678,
                 model_code: 
               }
               """
    end
  end
end
