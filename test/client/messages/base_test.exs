defmodule IbEx.Client.Messages.BaseTest do
  use ExUnit.Case

  alias IbEx.Client.Messages.Base

  describe "make_field/1" do
    test "makes an empty list as an empty field" do
      assert Base.make_field([]) == "\0"
    end

    test "makes nil as an empty field" do
      assert Base.make_field(nil) == "\0"
    end

    test "makes true as a field with '1'" do
      assert Base.make_field(true) == "1\0"
    end

    test "makes false as a field with '0'" do
      assert Base.make_field(false) == "0\0"
    end

    test "makes an integer as a field" do
      assert Base.make_field(180) == "180\0"
    end

    test "makes a binary as a field" do
      assert Base.make_field("IBM") == "IBM\0"
    end
  end

  describe "build/1" do
    test "builds the binary to be serialized down the wire" do
      fields = [18001, "test", true, 99]

      assert Base.build(fields) == <<
               49,
               56,
               48,
               48,
               49,
               0,
               116,
               101,
               115,
               116,
               0,
               49,
               0,
               57,
               57,
               0
             >>
    end
  end

  test "get_fields/1 splits the message in the different fields it has" do
    msg = <<49, 56, 48, 48, 49, 0, 116, 101, 115, 116, 0, 49, 0, 57, 57, 0>>

    assert Base.get_fields(msg) == [
             "18001",
             "test",
             "1",
             "99"
           ]
  end

  describe "message_id_from_fields/1" do
    test "returns an :ok tuple wit the integer value when successful" do
      fields = ["96", "test", "1", "99"]
      assert Base.message_id_from_fields(fields) == {:ok, "96"}
    end

    test "returns :error when the value can't be parsed" do
      fields = ["fsd96foo", "test", "1", "99"]
      assert Base.message_id_from_fields(fields) == :error
    end

    test "returns :error when called with a non-list" do
      assert Base.message_id_from_fields(nil) == :error
      assert Base.message_id_from_fields(55) == :error
      assert Base.message_id_from_fields("96") == :error
    end

    test "returns :error when called with a less of less than 2 elements" do
      assert Base.message_id_from_fields(["95"]) == :error
    end
  end
end
