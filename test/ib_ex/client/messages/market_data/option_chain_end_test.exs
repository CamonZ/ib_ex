defmodule IbEx.Client.Messages.MarketData.OptionChainEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.OptionChainEnd
  alias IbEx.Client.Protocols.Traceable

  @request_id 9001

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

  describe "Traceable" do
    test "to_s/1 returns a human readable version of the message" do
      assert Traceable.to_s(@msg) ==
               """
               <-- %MarketData.OptionChainEnd{
                 request_id: #{@request_id},
               }
               """
    end
  end
end
