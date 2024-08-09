defmodule IbEx.Client.Messages.MarketData.RequestMarketDataTypeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.RequestMarketDataType
  alias IbEx.Client.Messages.MarketData.MarketDataType

  describe "new/2" do
    test "creates the message with valid inputs" do
      assert {:ok, msg} = RequestMarketDataType.new(123, :delayed)

      assert msg.message_id == 59
      assert msg.request_id == 123
      assert msg.market_data_type == 3
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a serializable string" do
      msg = %RequestMarketDataType{
        message_id: 59,
        request_id: 123,
        market_data_type: 3
      }

      assert to_string(msg) == <<53, 57, 0, 49, 0>>
    end
  end

  describe "Inspect implementation" do
    test "returns a human-readable version of the struct" do
      msg = %RequestMarketDataType{
        message_id: 59,
        request_id: 123,
        market_data_type: 3
      }

      assert inspect(msg) ==
               """
               --> MarketData.RequestMarketDataType{
                 request_id: #{msg.request_id},
                 market_data_type: :#{MarketDataType.integer_to_atom(msg.market_data_type)}
               }
               """
    end
  end
end
