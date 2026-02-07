defmodule IbEx.Client.Messages.MarketData.OptionChainEndTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.OptionChainEnd
  alias IbEx.Client.Protocols.Traceable

  @request_id 9001

  @msg %OptionChainEnd{
    request_id: @request_id
  }

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
