defmodule IbEx.Client.Messages.MarketData.RequestMarketDataTypeTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Protocols.Traceable
  alias IbEx.Client.Messages.MarketData.RequestMarketDataType
  alias IbEx.Client.Messages.MarketData.MarketDataType
  alias IbEx.Client.Subscriptions

  describe "new/1" do
    test "creates the message with valid inputs" do
      assert {:ok, msg} = RequestMarketDataType.new(:delayed)

      assert msg.message_id == 59
      assert msg.market_data_type == 3
    end
  end

  describe "String.Chars implementation" do
    test "converts the message to a serializable string" do
      msg = %RequestMarketDataType{
        message_id: 59,
        market_data_type: 3
      }

      assert to_string(msg) == <<53, 57, 0, 49, 0, 51, 0>>
    end
  end

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the struct" do
      msg = %RequestMarketDataType{
        message_id: 59,
        market_data_type: 3
      }

      assert Traceable.to_s(msg) ==
               """
               --> MarketData.RequestMarketDataType{
                 market_data_type: :#{MarketDataType.integer_to_atom(msg.market_data_type)}
               }
               """
    end
  end

  describe "Subscribable" do
    test "subscribes the message" do
      pid = self()
      table_ref = Subscriptions.initialize()
      {:ok, msg} = RequestMarketDataType.new(:delayed)
      {:ok, subscribed_msg} = Subscribable.subscribe(msg, pid, table_ref)

      assert {:ok, ^pid} = Subscribable.lookup(subscribed_msg, table_ref)
    end
  end
end
