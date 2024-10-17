defmodule IbEx.Client.Messages.MarketData.Tick.OptionComputationTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketData.Tick.OptionComputation
  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  @request_id "9001"
  def fields(request_id) do
    [
      request_id,
      "83",
      "0",
      "0.5099480112843168",
      "0.2580487018296367",
      "4.044118115579977",
      "0.009916152757821517",
      "0.011165298670040383",
      "0.1903185064903541",
      "-0.06499055635114762",
      "124.2"
    ]
  end

  describe "from_fields/1" do
    test "creates OptionComputation struct with valid fields" do
      assert {:ok, msg} = OptionComputation.from_fields(fields(@request_id))

      assert msg.request_id == "9001"
      assert msg.tick_type == :delayed_model_option
      assert msg.tick_attr == 0
      assert msg.implied_volatility == Decimal.new("0.5099480112843168")
      assert msg.delta == Decimal.new("0.2580487018296367")
      assert msg.option_price == Decimal.new("4.044118115579977")
      assert msg.pv_dividend == Decimal.new("0.009916152757821517")
      assert msg.gamma == Decimal.new("0.011165298670040383")
      assert msg.vega == Decimal.new("0.1903185064903541")
      assert msg.theta == Decimal.new("-0.06499055635114762")
      assert msg.underlying_price == Decimal.new("124.2")
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args, [{:from_fields, 1}, ["123", "1"]]} == OptionComputation.from_fields(["123", "1"])
    end
  end

  describe "Inspect implementation" do
    test "inspects TickSize struct correctly" do
      msg = %OptionComputation{
        request_id: "9001",
        tick_type: :delayed_model_option,
        tick_attr: 0,
        implied_volatility: Decimal.new("0.5099480112843168"),
        delta: Decimal.new("0.2580487018296367"),
        option_price: Decimal.new("4.044118115579977"),
        pv_dividend: Decimal.new("0.009916152757821517"),
        gamma: Decimal.new("0.011165298670040383"),
        vega: Decimal.new("0.1903185064903541"),
        theta: Decimal.new("-0.06499055635114762"),
        underlying_price: Decimal.new("124.2")
      }

      assert inspect(msg) ==
               """
               <-- %MarketData.Tick.OptionComputation{
                 request_id: #{msg.request_id},
                 tick_type: #{msg.tick_type},
                 tick_attr: #{msg.tick_attr},
                 option_price: #{msg.option_price},
                 underlying_price: #{msg.underlying_price},
                 implied_volatility: #{msg.implied_volatility},
                 delta: #{msg.delta},
                 gamma: #{msg.gamma},
                 vega: #{msg.vega},
                 theta: #{msg.theta},
                 pv_dividend: #{msg.pv_dividend}
               }
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_request_id(table_ref, self())
      {:ok, msg} = OptionComputation.from_fields(fields("1"))

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)
      assert pid == self()
    end
  end
end
