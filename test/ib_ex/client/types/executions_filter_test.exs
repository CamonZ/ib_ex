defmodule IbEx.Client.Types.ExecutionsFilterTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.ExecutionsFilter

  describe "new/1" do
    test "creates an ExecutionsFilter with valid options" do
      opts = [
        client_id: 123,
        account_id: "ABC123",
        time: "2023-12-05",
        symbol: "XYZ",
        security_type: "STOCK",
        exchange: "NYSE",
        side: "BUY"
      ]

      {:ok, filter} = ExecutionsFilter.new(opts)
      assert filter.client_id == 123
      assert filter.account_id == "ABC123"
      assert filter.time == "2023-12-05"
      assert filter.symbol == "XYZ"
      assert filter.security_type == "STOCK"
      assert filter.exchange == "NYSE"
      assert filter.side == "BUY"
    end

    test "returns an error with invalid input" do
      invalid_input = "invalid"
      assert {:error, :invalid_args} == ExecutionsFilter.new(invalid_input)
    end

    test "creates an ExecutionsFilter with partial options" do
      opts = [client_id: 123, account_id: "ABC123"]

      {:ok, filter} = ExecutionsFilter.new(opts)
      assert filter.client_id == 123
      assert filter.account_id == "ABC123"
      assert is_nil(filter.time)
      assert is_nil(filter.symbol)
      assert is_nil(filter.security_type)
      assert is_nil(filter.exchange)
      assert is_nil(filter.side)
    end

    test "handles empty options" do
      {:ok, filter} = ExecutionsFilter.new([])
      assert is_nil(filter.client_id)
      assert is_nil(filter.account_id)
      assert is_nil(filter.time)
      assert is_nil(filter.symbol)
      assert is_nil(filter.security_type)
      assert is_nil(filter.exchange)
      assert is_nil(filter.side)
    end
  end
end
