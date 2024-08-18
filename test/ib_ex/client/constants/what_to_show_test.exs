defmodule IbEx.Client.Constants.WhatToShowTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Constants.WhatToShow

  describe "format/1" do
    test "creates valid what_to_show format" do
      assert WhatToShow.format(:ask) == "ASK"
      assert WhatToShow.format(:bid) == "BID"
      assert WhatToShow.format(:bid_ask) == "BID_ASK"
      assert WhatToShow.format(:fee_rate) == "FEE_RATE"
      assert WhatToShow.format(:historical_volatility) == "HISTORICAL_VOLATILITY"
      assert WhatToShow.format(:midpoint) == "MIDPOINT"
      assert WhatToShow.format(:option_implied_volatility) == "OPTION_IMPLIED_VOLATILITY"
      assert WhatToShow.format(:schedule) == "SCHEDULE"
      assert WhatToShow.format(:trades) == "TRADES"
      assert WhatToShow.format(:yield_ask) == "YIELD_ASK"
      assert WhatToShow.format(:yield_bid_ask) == "YIELD_BID_ASK"
      assert WhatToShow.format(:yield_last) == "YIELD_LAST"
    end

    test "returns :invalid_args for bad arguments" do
      assert WhatToShow.format("bad_arg") == :invalid_args
    end
  end
end
