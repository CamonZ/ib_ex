defmodule IbEx.Client.Types.NewsProviderTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Types.NewsProvider

  describe "new/0" do
    test "creates a NewsProvider struct with default attributes" do
      assert NewsProvider.new() == %NewsProvider{
               code: nil,
               name: nil
             }
    end
  end

  describe "new/1" do
    test "creates a NewsProvider struct from a map" do
      params = %{code: "BRFG", name: "Briefing.com General Market Columns"}

      result = NewsProvider.new(params)

      assert result.code == "BRFG"
      assert result.name == "Briefing.com General Market Columns"
    end

    test "creates a NewsProvider struct from a keyword list" do
      params = [code: "DJNL", name: "Dow Jones Newsletters"]

      result = NewsProvider.new(params)

      assert result.code == "DJNL"
      assert result.name == "Dow Jones Newsletters"
    end
  end
end
