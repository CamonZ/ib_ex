defmodule IbEx.Client.Messages.MarketDepth.ExchangesTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.MarketDepth.Exchanges
  alias IbEx.Client.Types.MarketDepthDescription

  alias IbEx.Client.Protocols.Subscribable
  alias IbEx.Client.Subscriptions

  @fields [
    "3",
    "NYSE",
    "STK",
    "NASD",
    "DataType1",
    "1",
    "NASDAQ",
    "OPT",
    "NYSE",
    "DataType2",
    "2",
    "CME",
    "FUT",
    "GLOBEX",
    "DataType3",
    "3"
  ]

  describe "from_fields/1" do
    test "creates Exchanges with valid fields" do
      assert {:ok, msg} = Exchanges.from_fields(@fields)

      [nyse_stock, nasdaq_opt, cme_fut] = msg.items

      assert %MarketDepthDescription{exchange: "NYSE", security_type: "STK"} = nyse_stock
      assert %MarketDepthDescription{exchange: "NASDAQ", security_type: "OPT"} = nasdaq_opt
      assert %MarketDepthDescription{exchange: "CME", security_type: "FUT"} = cme_fut
    end

    test "returns an error with invalid fields" do
      assert {:error, :invalid_args} == Exchanges.from_fields(["invalid"])
    end
  end

  describe "Inspect" do
    test "inspect/2 Exchanges struct correctly" do
      description = %MarketDepthDescription{
        exchange: "NYSE",
        security_type: "STK"
      }

      assert inspect(%Exchanges{items: [description]}) ==
               """
               <-- %MarketDepth.Exchanges{items: [%MarketDepthDescription{exchange: NYSE, security_type: STK}]}
               """
    end
  end

  describe "Subscribable" do
    test "looks up the message in the subscriptions mapping" do
      table_ref = Subscriptions.initialize()
      Subscriptions.subscribe_by_modules(table_ref, [Exchanges], self())

      {:ok, msg} = Exchanges.from_fields(@fields)

      assert {:ok, pid} = Subscribable.lookup(msg, table_ref)

      assert pid == self()
    end
  end
end
