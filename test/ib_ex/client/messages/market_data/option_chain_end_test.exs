defmodule IbEx.Client.Messages.MarketData.OptionChainEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.OptionChainEnd

  
  @request_id 9001
  @message_id "76"

  @msg %OptionChainEnd{
    request_id: @request_id
  }

  describe "from_fields/1" do
    test "creates OptionChainEnd struct with valid fields" do
      assert {:ok, msg} = OptionChainEnd.from_fields([@request_id])

      assert msg.request_id == @request_id
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == OptionChainEnd.from_fields([])
    end
  end

  describe "Inspect implementation" do
    test "inspects OptionChainEnd struct correctly" do
      assert inspect(@msg) ==
               """
               <-- %MarketData.OptionChainEnd{
                 request_id: #{@request_id},
               }
               """
    end
  end
end
