defmodule IbEx.Client.Messages.Executions.RequestTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.Executions.Request
  alias IbEx.Client.Types.ExecutionsFilter

  describe "new/2" do
    test "creates a Request with valid inputs" do
      assert {:ok, msg} = Request.new(90001, %ExecutionsFilter{client_id: 123})

      assert msg.message_id == 7
      assert msg.request_id == 90001
      assert msg.filter == %ExecutionsFilter{client_id: 123}
    end
  end

  describe "String.Chars implementation" do
    test "converts Request struct to string" do
      msg = %Request{
        message_id: 7,
        version: 3,
        request_id: 90001,
        filter: %ExecutionsFilter{client_id: 123}
      }

      assert to_string(msg) == <<55, 0, 51, 0, 57, 48, 48, 48, 49, 0, 49, 50, 51, 0, 0, 0, 0, 0, 0, 0>>
    end
  end

  describe "inspect/2" do
    test "returns a human-readable version of the message" do
      msg = %Request{
        message_id: 7,
        request_id: 90001,
        filter: %ExecutionsFilter{client_id: 123}
      }

      assert inspect(msg) ==
               """
               --> Executions.Request{
                 message_id: 7,
                 request_id: 90001,
                 filter: %IbEx.Client.Types.ExecutionsFilter{client_id: 123, account_id: nil, time: nil, symbol: nil, security_type: nil, exchange: nil, side: nil}
               }
               """
    end
  end
end
