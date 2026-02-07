defmodule IbEx.Client.Messages.News.ProvidersTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.Providers
  alias IbEx.Client.Protocols.Traceable

  describe "Traceable" do
    test "to_s/1 returns a human-readable version of the message" do
      msg = %Providers{
        items: [{"code1", "name1"}, {"code2", "name2"}]
      }

      assert Traceable.to_s(msg) ==
               """
               <-- %News.Providers{items: [{\"code1\", \"name1\"}, {\"code2\", \"name2\"}]}
               """
    end
  end
end
