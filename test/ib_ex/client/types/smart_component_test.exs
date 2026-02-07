defmodule IbEx.Client.Types.SmartComponentTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.SmartComponent

  describe "new/0" do
    test "creates a SmartComponent struct with default attributes" do
      assert SmartComponent.new() == %SmartComponent{
               bit_number: nil,
               exchange: nil,
               exchange_letter: nil
             }
    end
  end

  describe "new/1" do
    test "creates a SmartComponent struct from a map" do
      params = %{bit_number: 0, exchange: "NYSE", exchange_letter: "N"}

      result = SmartComponent.new(params)

      assert result.bit_number == 0
      assert result.exchange == "NYSE"
      assert result.exchange_letter == "N"
    end

    test "creates a SmartComponent struct from a keyword list" do
      params = [bit_number: 1, exchange: "ARCA", exchange_letter: "P"]

      result = SmartComponent.new(params)

      assert result.bit_number == 1
      assert result.exchange == "ARCA"
      assert result.exchange_letter == "P"
    end
  end
end
