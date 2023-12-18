defmodule IbEx.Client.Messages.MarketData.TickPriceTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.TickPrice

  describe "from_fields/1" do
    test "creates the message valid fields" do
      assert {:ok, msg} = TickPrice.from_fields(["6", "123", "1", "100.5", "200", "7"])

      assert msg.request_id == "123"
      assert msg.tick_type == :bid
      assert msg.price == 100.5
      assert msg.size == Decimal.new("200")
      assert msg.can_autoexecute?
      assert msg.past_limit?
      assert msg.pre_open?
      refute msg.should_tick_for_size?
    end

    test "returns an error with invalid args" do
      assert {:error, :invalid_args} == TickPrice.from_fields(["123", "1", "100.50", "200"])
    end
  end

  describe "Inspect implementation" do
    test "inspects TickPrice struct correctly" do
      msg = %TickPrice{
        request_id: "123",
        tick_type: :bid,
        price: 100.5,
        size: Decimal.new("200"),
        can_autoexecute?: true,
        past_limit?: false,
        pre_open?: true,
        should_tick_for_size?: false
      }

      assert inspect(msg) ==
               """
               <-- %MarketData.TickPrice{
                 request_id: 123,
                 tick_type: bid,
                 price: 100.5,
                 size: 200,
                 can_autoexecute?: true,
                 past_limit?: false,
                 pre_open?: true,
                 should_tick_for_size?: false
               }
               """
    end
  end
end
