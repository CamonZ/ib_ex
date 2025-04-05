defmodule IbEx.Client.Messages.News.ProvidersTest do
  use ExUnit.Case, async: true

  alias IbEx.Client.Messages.News.Providers
  alias IbEx.Client.Protocols.Traceable

  describe "from_fields/1" do
    test "creates the message with valid fields" do
      fields = ["3", "code1", "name1", "code2", "name2", "code3", "name3"]

      assert {:ok, msg} = Providers.from_fields(fields)

      [provider_1, provider_2, provider_3] = msg.items

      assert provider_1 == {"code1", "name1"}
      assert provider_2 == {"code2", "name2"}
      assert provider_3 == {"code3", "name3"}
    end

    test "returns an error with insufficient fields" do
      assert {:error, :invalid_args} == Providers.from_fields(["1", "code1"])
    end
  end

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
