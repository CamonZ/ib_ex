defmodule IbEx.Client.Constants.WhatToShowTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Constants.WhatToShow

  describe "format/1" do
    test "creates valid what_to_show format" do
      assert WhatToShow.format(:ask) == {:ok, "ASK"}
      assert WhatToShow.format(:bid) == {:ok, "BID"}
      assert WhatToShow.format(:bid_ask) == {:ok, "BID_ASK"}
      assert WhatToShow.format(:fee_rate) == {:ok, "FEE_RATE"}
      assert WhatToShow.format(:historical_volatility) == {:ok, "HISTORICAL_VOLATILITY"}
      assert WhatToShow.format(:midpoint) == {:ok, "MIDPOINT"}
      assert WhatToShow.format(:option_implied_volatility) == {:ok, "OPTION_IMPLIED_VOLATILITY"}
      assert WhatToShow.format(:schedule) == {:ok, "SCHEDULE"}
      assert WhatToShow.format(:trades) == {:ok, "TRADES"}
      assert WhatToShow.format(:yield_ask) == {:ok, "YIELD_ASK"}
      assert WhatToShow.format(:yield_bid_ask) == {:ok, "YIELD_BID_ASK"}
      assert WhatToShow.format(:yield_last) == {:ok, "YIELD_LAST"}
    end

    test "returns :invalid_args for bad arguments" do
      assert WhatToShow.format(:bad_arg) == {:error, :invalid_args}
    end
  end
end
